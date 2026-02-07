//Copyright © 2021 Apple Inc. All rights reserved.

/*import SwiftUI
import Network

class OBDConnection: ObservableObject {
    private var connection: NWConnection?
    @Published var rpm: String = "--"
    
    func connect() {
        // iCar Pro WiFi default IP/port
        let host = NWEndpoint.Host("192.168.0.10")
        let port = NWEndpoint.Port(rawValue: 35000)!
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        connection?.stateUpdateHandler = { state in
            print("Connection state: \(state)")
            if case .ready = state {
                self.initialize()
            }
        }
        
        connection?.start(queue: .global())
    }
    
    private func initialize() {
        // Common init commands
        send("ATZ\r")   // reset
        send("ATE0\r")  // echo off
        send("ATL0\r")  // linefeeds off
        send("ATS0\r")  // spaces off
        send("ATH0\r")  // headers off
        send("ATSP0\r") // auto protocol
        
        // Request RPM after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.requestRPM()
        }
    }
    
    private func requestRPM() {
        send("010C\r") // PID for RPM
        receive()
    }
    
    private func send(_ command: String) {
        guard let connection = connection else { return }
        let data = command.data(using: .utf8)!
        connection.send(content: data, completion: .contentProcessed({ _ in }))
    }
    
    private func receive() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, _ in
            if let data = data, let response = String(data: data, encoding: .utf8) {
                print("Raw Response: \(response)")
                self.parseRPM(from: response)
            }
            self.receive() // keep listening
        }
    }
    
    private func parseRPM(from response: String) {
        // Example response: "41 0C 1A F8"
        let parts = response.split(separator: " ")
        if parts.count >= 4, parts[0] == "41", parts[1] == "0C" {
            if let A = UInt16(parts[2], radix: 16),
               let B = UInt16(parts[3], radix: 16) {
                let rpmValue = ((A * 256) + B) / 4
                DispatchQueue.main.async {
                    self.rpm = "\(rpmValue) RPM"
                }
            }
        }
    }
}

struct ContentView: View {
    @StateObject private var obd = OBDConnection()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Engine RPM")
                .font(.title)
            Text(obd.rpm)
                .font(.largeTitle)
                .bold()
            
            Button("Connect to OBD-II") {
                obd.connect()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
*/


import SwiftUI
import Network

class OBDConnection: ObservableObject {
    private var connection: NWConnection?
    private var isWaitingForResponse = false
    private var pollingTimer: Timer?
    private var currentParameterIndex = 0
    private var isActive = false

    // Demo mode
    @Published var isDemoMode = false
    private var demoTimer: Timer?
    private var demoValues: [OBDParameterType: Double] = [:]

    @Published var parameters: [OBDParameterData] = []
    @Published var isConnected = false

    // DTC manager reference for routing Mode 03/04 responses
    weak var dtcManager: DTCManager?

    // Track whether we're currently doing a DTC scan/clear (pauses parameter polling)
    private var isDTCOperation = false

    init() {
        // Initialize all parameters with N/A values
        parameters = OBDParameterType.allCases.map { type in
            OBDParameterData(type: type, value: "N/A", lastUpdated: Date())
        }
        // Seed demo values at midpoints
        demoValues = [
            .rpm: 1200, .speed: 60, .coolantTemp: 90, .engineLoad: 50,
            .throttlePosition: 30, .fuelLevel: 55, .intakeAirTemp: 28,
            .maf: 8.0, .timing: 10.0
        ]
    }

    // MARK: - Demo Mode

    func startDemo() {
        // Stop any real connection first (without resetting isDemoMode)
        isActive = false
        pollingTimer?.invalidate()
        pollingTimer = nil
        connection?.cancel()
        connection = nil
        isWaitingForResponse = false

        isDemoMode = true
        isConnected = true

        demoTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.updateDemoValues()
        }
        // Fire immediately for instant feedback
        updateDemoValues()
    }

    func stopDemo() {
        demoTimer?.invalidate()
        demoTimer = nil
        isDemoMode = false
        isConnected = false
        parameters = OBDParameterType.allCases.map { type in
            OBDParameterData(type: type, value: "--", lastUpdated: Date())
        }
    }

    private func updateDemoValues() {
        let ranges: [OBDParameterType: (min: Double, max: Double, drift: Double)] = [
            .rpm:              (650,  3500, 150),
            .speed:            (0,    120,  8),
            .coolantTemp:      (80,   100,  2),
            .engineLoad:       (20,   85,   5),
            .throttlePosition: (5,    75,   6),
            .fuelLevel:        (25,   90,   1),
            .intakeAirTemp:    (15,   45,   2),
            .maf:              (2.0,  15.0, 1.0),
            .timing:           (-5.0, 25.0, 2.0)
        ]

        for paramType in OBDParameterType.allCases {
            guard let range = ranges[paramType],
                  let current = demoValues[paramType] else { continue }

            // Drift slightly from previous value
            let delta = Double.random(in: -range.drift...range.drift)
            let newValue = min(range.max, max(range.min, current + delta))
            demoValues[paramType] = newValue

            let formatted: String
            switch paramType {
            case .maf, .timing:
                formatted = String(format: "%.1f", newValue)
            default:
                formatted = "\(Int(newValue))"
            }

            if let index = parameters.firstIndex(where: { $0.type == paramType }) {
                parameters[index] = OBDParameterData(
                    type: paramType,
                    value: formatted,
                    lastUpdated: Date()
                )
            }
        }
    }

    // MARK: - Real DTC Scanning (Mode 03 / Mode 04)

    func scanForDTCs() {
        guard isConnected, !isDemoMode, let connection = connection else { return }
        dtcManager?.isScanning = true
        dtcManager?.scanError = nil
        isDTCOperation = true
        isWaitingForResponse = false // cancel any pending parameter poll

        let data = "03\r".data(using: .utf8)!
        print("Sending: 03 (Read DTCs)")
        connection.send(content: data, completion: .contentProcessed({ _ in }))

        // Timeout — if no response after 10s, report error
        DispatchQueue.global().asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self, self.isDTCOperation else { return }
            self.isDTCOperation = false
            self.dtcManager?.handleError("No response from vehicle. Check connection.")
            self.resumePolling()
        }
    }

    func clearDTCs() {
        guard isConnected, !isDemoMode, let connection = connection else { return }
        dtcManager?.isClearing = true
        dtcManager?.scanError = nil
        isDTCOperation = true
        isWaitingForResponse = false

        let data = "04\r".data(using: .utf8)!
        print("Sending: 04 (Clear DTCs)")
        connection.send(content: data, completion: .contentProcessed({ _ in }))

        // Timeout
        DispatchQueue.global().asyncAfter(deadline: .now() + 10.0) { [weak self] in
            guard let self = self, self.isDTCOperation else { return }
            self.isDTCOperation = false
            self.dtcManager?.handleError("Clear command timed out. Try again.")
            self.resumePolling()
        }
    }

    private func resumePolling() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, self.isActive else { return }
            self.sendNextParameter()
        }
    }

    func connect() {
        let host = NWEndpoint.Host("192.168.0.10")   // default IP for iCar Pro WiFi
        let port = NWEndpoint.Port(rawValue: 35000)!

        isActive = true
        connection = NWConnection(host: host, port: port, using: .tcp)
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            print("Connection state: \(state)")
            switch state {
            case .ready:
                DispatchQueue.main.async { self.isConnected = true }
                self.startListening()
                self.initialize()
            case .failed, .cancelled:
                self.isActive = false
                DispatchQueue.main.async { self.isConnected = false }
            case .waiting:
                // Connection can't be established — clean up
                self.isActive = false
                self.connection?.cancel()
                DispatchQueue.main.async { self.isConnected = false }
            default:
                break
            }
        }

        connection?.start(queue: .global())
    }

    func disconnect() {
        isActive = false
        pollingTimer?.invalidate()
        pollingTimer = nil
        connection?.cancel()
        connection = nil
        isWaitingForResponse = false
        DispatchQueue.main.async {
            self.isConnected = false
            self.parameters = OBDParameterType.allCases.map { type in
                OBDParameterData(type: type, value: "N/A", lastUpdated: Date())
            }
        }
    }

    private func startListening() {
        guard isActive, let connection = connection else { return }
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, _, _ in
            guard let self = self, self.isActive else { return }
            if let data = data, let response = String(data: data, encoding: .utf8) {
                let cleanResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
                print("Raw Response: \(cleanResponse)")
                self.handleResponse(cleanResponse)
            }
            self.startListening()
        }
    }

    private func initialize() {
        // Send initialization commands sequentially with proper delays
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, self.isActive else { return }
            self.sendCommand("ATZ\r")  // Reset
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self, self.isActive else { return }
            self.sendCommand("ATE0\r") // Echo off
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self, self.isActive else { return }
            self.sendCommand("ATL0\r") // Linefeeds off
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self = self, self.isActive else { return }
            self.sendCommand("ATS0\r") // Spaces off
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self, self.isActive else { return }
            self.sendCommand("ATH0\r") // Headers off
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 6.0) { [weak self] in
            guard let self = self, self.isActive else { return }
            self.sendCommand("ATSP0\r") // Auto protocol
        }

        // Start polling after ALL initialization commands complete (8 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) { [weak self] in
            guard let self = self, self.isActive else { return }
            print("Starting polling...")
            self.startPolling()
        }
    }

    private func startPolling() {
        // Send the first command to start the polling cycle
        sendNextParameter()
    }

    private func sendNextParameter() {
        guard isActive, connection != nil else { return }

        // Get the current parameter to poll
        let paramTypes = Array(OBDParameterType.allCases)
        let paramType = paramTypes[currentParameterIndex]

        // Send the command
        sendCommand("\(paramType.pid)\r")

        // Move to next parameter for the next cycle
        currentParameterIndex = (currentParameterIndex + 1) % paramTypes.count
    }

    private func sendCommand(_ command: String) {
        guard isActive, let connection = connection else { return }
        print("Sending: \(command.trimmingCharacters(in: .whitespacesAndNewlines))")
        let data = command.data(using: .utf8)!
        connection.send(content: data, completion: .contentProcessed({ _ in }))

        isWaitingForResponse = true

        // Longer timeout (8 seconds) to allow for SEARCHING and ECU response
        DispatchQueue.global().asyncAfter(deadline: .now() + 8.0) { [weak self] in
            guard let self = self, self.isActive else { return }
            if self.isWaitingForResponse {
                print("Timeout waiting for response to: \(command.trimmingCharacters(in: .whitespacesAndNewlines))")
                self.isWaitingForResponse = false

                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) { [weak self] in
                    guard let self = self, self.isActive else { return }
                    self.sendNextParameter()
                }
            }
        }
    }

    private func handleResponse(_ response: String) {
        guard isActive else { return }
        // Ignore empty responses and prompts
        guard !response.isEmpty && response != ">" else { return }

        // Ignore common non-data responses (don't mark as ready for next command)
        if response.contains("SEARCHING") {
            print("Searching for protocol...")
            return
        }

        if response.contains("STOPPED") {
            print("Command stopped - waiting before retry")
            isWaitingForResponse = false
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self, self.isActive else { return }
                self.sendNextParameter()
            }
            return
        }

        // Handle NO DATA responses (vehicle doesn't support this parameter)
        if response.contains("NO DATA") {
            print("No data for this parameter - skipping")
            isWaitingForResponse = false
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self, self.isActive else { return }
                self.sendNextParameter()
            }
            return
        }

        // Ignore echo responses (command being echoed back)
        if response.starts(with: "01") && response.count <= 4 {
            print("Echo ignored: \(response)")
            return
        }

        // Ignore AT command responses and OK
        if response.contains("AT") || response == "OK" || response.contains("ELM") {
            isWaitingForResponse = false
            return
        }

        // Ignore negative response codes
        if response.hasPrefix("7F") {
            // Check if this is a DTC operation error (7F03 or 7F04)
            let cleanHex = response.replacingOccurrences(of: " ", with: "")
            if isDTCOperation && (cleanHex.hasPrefix("7F03") || cleanHex.hasPrefix("7F04")) {
                isDTCOperation = false
                dtcManager?.handleError("Vehicle rejected the request. Try again.")
                resumePolling()
                return
            }
            print("Negative response from ECU: \(response) - trying next parameter")
            isWaitingForResponse = false
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self, self.isActive else { return }
                self.sendNextParameter()
            }
            return
        }

        // Handle Mode 03 response (Read DTCs) — "43 ..."
        let compactResponse = response.replacingOccurrences(of: " ", with: "").uppercased()
        if compactResponse.hasPrefix("43") {
            print("Mode 03 DTC response: \(response)")
            isDTCOperation = false
            dtcManager?.processReadDTCsResponse(response)
            isWaitingForResponse = false
            resumePolling()
            return
        }

        // Handle Mode 04 response (Clear DTCs) — "44"
        if compactResponse.hasPrefix("44") {
            print("Mode 04 Clear DTCs response: \(response)")
            isDTCOperation = false
            dtcManager?.processClearDTCsResponse(response)
            isWaitingForResponse = false
            resumePolling()
            return
        }

        // Handle NO DATA during DTC scan (means no stored DTCs)
        if isDTCOperation && response.contains("NO DATA") {
            print("No DTCs stored in vehicle")
            isDTCOperation = false
            dtcManager?.handleNoData()
            isWaitingForResponse = false
            resumePolling()
            return
        }

        // Try to parse response for each parameter type
        var parsed = false
        for paramType in OBDParameterType.allCases {
            if let value = paramType.parseValue(from: response) {
                print("✓ Parsed \(paramType.title): \(value) from response: \(response)")
                updateParameter(type: paramType, value: value)
                parsed = true
                break
            }
        }

        if !parsed && response.hasPrefix("41") {
            print("⚠️ Unable to parse OBD response: \(response)")
        }

        // Mark as ready for next command after receiving data
        isWaitingForResponse = false

        // Send next parameter after short delay
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self, self.isActive else { return }
            self.sendNextParameter()
        }
    }

    private func updateParameter(type: OBDParameterType, value: String) {
        DispatchQueue.main.async {
            if let index = self.parameters.firstIndex(where: { $0.type == type }) {
                self.parameters[index] = OBDParameterData(
                    type: type,
                    value: value,
                    lastUpdated: Date()
                )
                print("✓ UI Updated: \(type.title) = \(value)")
            }
        }
    }
}

// Shared accent color matching the reference design
let accentGreen = Color(red: 0.35, green: 0.85, blue: 0.40)
let cardBackground = Color(red: 0.10, green: 0.14, blue: 0.12)

struct ContentView: View {
    @StateObject private var obd = OBDConnection()
    @StateObject private var dtcManager = DTCManager()

    var body: some View {
        TabView {
            DashboardView(obd: obd)
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent")
                }

            DiagnosticsView(obd: obd, dtcManager: dtcManager)
                .tabItem {
                    Label("Diagnostics", systemImage: "exclamationmark.triangle")
                }
                .badge(dtcManager.activeDTCs.count > 0 ? dtcManager.activeDTCs.count : 0)

            SettingsView(obd: obd, dtcManager: dtcManager)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .preferredColorScheme(.dark)
        .tint(accentGreen)
        .onAppear {
            obd.dtcManager = dtcManager
        }
        .onChange(of: obd.isDemoMode) { _, newValue in
            if newValue {
                dtcManager.startDemoMode()
            } else {
                dtcManager.stopDemoMode()
            }
        }
    }
}
