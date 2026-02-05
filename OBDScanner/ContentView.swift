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

    @Published var parameters: [OBDParameterData] = []
    @Published var isConnected = false

    init() {
        // Initialize all parameters with N/A values
        parameters = OBDParameterType.allCases.map { type in
            OBDParameterData(type: type, value: "N/A", lastUpdated: Date())
        }
    }

    func connect() {
        let host = NWEndpoint.Host("192.168.0.10")   // default IP for iCar Pro WiFi
        let port = NWEndpoint.Port(rawValue: 35000)!

        connection = NWConnection(host: host, port: port, using: .tcp)
        connection?.stateUpdateHandler = { state in
            print("Connection state: \(state)")
            if case .ready = state {
                DispatchQueue.main.async {
                    self.isConnected = true
                }
                self.startListening()
                self.initialize()
            } else if case .failed = state {
                DispatchQueue.main.async {
                    self.isConnected = false
                }
            } else if case .cancelled = state {
                DispatchQueue.main.async {
                    self.isConnected = false
                }
            }
        }

        connection?.start(queue: .global())
    }

    func disconnect() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        connection?.cancel()
        connection = nil
        DispatchQueue.main.async {
            self.isConnected = false
            // Reset all values to N/A
            self.parameters = OBDParameterType.allCases.map { type in
                OBDParameterData(type: type, value: "N/A", lastUpdated: Date())
            }
        }
    }

    private func startListening() {
        guard let connection = connection,
              connection.state == .ready else { return }
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, _ in
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
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            self.sendCommand("ATZ\r")  // Reset
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            self.sendCommand("ATE0\r") // Echo off
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 3.0) {
            self.sendCommand("ATL0\r") // Linefeeds off
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 4.0) {
            self.sendCommand("ATS0\r") // Spaces off
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
            self.sendCommand("ATH0\r") // Headers off
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 6.0) {
            self.sendCommand("ATSP0\r") // Auto protocol
        }

        // Start polling after ALL initialization commands complete (8 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
            print("🚀 Starting polling...")
            self.startPolling()
        }
    }

    private func startPolling() {
        // Send the first command to start the polling cycle
        sendNextParameter()
    }

    private func sendNextParameter() {
        guard connection != nil, connection?.state == .ready else { return }

        // Get the current parameter to poll
        let paramTypes = Array(OBDParameterType.allCases)
        let paramType = paramTypes[currentParameterIndex]

        // Send the command
        sendCommand("\(paramType.pid)\r")

        // Move to next parameter for the next cycle
        currentParameterIndex = (currentParameterIndex + 1) % paramTypes.count
    }

    private func sendCommand(_ command: String) {
        guard let connection = connection,
              connection.state == .ready else { return }
        print("Sending: \(command.trimmingCharacters(in: .whitespacesAndNewlines))")
        let data = command.data(using: .utf8)!
        connection.send(content: data, completion: .contentProcessed({ _ in }))

        isWaitingForResponse = true

        // Longer timeout (8 seconds) to allow for SEARCHING and ECU response
        DispatchQueue.global().asyncAfter(deadline: .now() + 8.0) {
            if self.isWaitingForResponse {
                print("⏱ Timeout waiting for response to: \(command.trimmingCharacters(in: .whitespacesAndNewlines))")
                self.isWaitingForResponse = false

                // Try next parameter after timeout
                DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                    self.sendNextParameter()
                }
            }
        }
    }

    private func handleResponse(_ response: String) {
        // Ignore empty responses and prompts
        guard !response.isEmpty && response != ">" else { return }

        // Ignore common non-data responses (don't mark as ready for next command)
        if response.contains("SEARCHING") {
            print("🔍 Searching for protocol...")
            return
        }

        if response.contains("STOPPED") {
            print("⏹ Command stopped - waiting before retry")
            isWaitingForResponse = false
            // If stopped, wait longer before trying next (2 seconds to let adapter settle)
            DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                self.sendNextParameter()
            }
            return
        }

        // Handle NO DATA responses (vehicle doesn't support this parameter)
        if response.contains("NO DATA") {
            print("⚠️ No data for this parameter - skipping")
            isWaitingForResponse = false
            // Skip to next parameter quickly
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                self.sendNextParameter()
            }
            return
        }

        // Ignore echo responses (command being echoed back)
        if response.starts(with: "01") && response.count <= 4 {
            print("↩️ Echo ignored: \(response)")
            return
        }

        // Ignore AT command responses and OK
        if response.contains("AT") || response == "OK" || response.contains("ELM") {
            isWaitingForResponse = false
            return
        }

        // Ignore negative response codes
        if response.hasPrefix("7F") {
            print("⚠️ Negative response from ECU: \(response) - trying next parameter")
            isWaitingForResponse = false
            // Send next parameter after short delay
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                self.sendNextParameter()
            }
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
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Connection status banner
                    ConnectionStatusBanner(isConnected: obd.isConnected)

                    // Connection button
                    if !obd.isConnected {
                        Button(action: {
                            obd.connect()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "bolt.circle.fill")
                                    .font(.title3)
                                Text("Connect to OBD-II")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(accentGreen)
                            .cornerRadius(14)
                            .shadow(color: accentGreen.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(.horizontal)
                    } else {
                        Button(action: {
                            obd.disconnect()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                Text("Disconnect")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(white: 0.20))
                            .cornerRadius(14)
                        }
                        .padding(.horizontal)
                    }

                    // Grid of parameters
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 14),
                        GridItem(.flexible(), spacing: 14)
                    ], spacing: 14) {
                        ForEach(obd.parameters) { parameter in
                            NavigationLink(destination: ParameterDetailView(parameter: parameter)) {
                                ParameterCardView(parameter: parameter)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .navigationTitle("OBD Scanner")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(Color.black.ignoresSafeArea())
        }
        .preferredColorScheme(.dark)
    }
}

struct ConnectionStatusBanner: View {
    let isConnected: Bool

    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? accentGreen : Color.gray)
                .frame(width: 10, height: 10)
                .shadow(color: isConnected ? accentGreen.opacity(0.6) : .clear, radius: 4)

            Text(isConnected ? "Connected" : "Not Connected")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Spacer()

            if isConnected {
                HStack(spacing: 4) {
                    Image(systemName: "wifi")
                        .foregroundColor(accentGreen)
                    Text("192.168.0.10")
                }
                .font(.caption)
                .foregroundColor(Color(white: 0.5))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentGreen.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}
