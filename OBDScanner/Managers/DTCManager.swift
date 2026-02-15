import SwiftUI
import Combine

class DTCManager: ObservableObject {
    @Published var activeDTCs: [ActiveDTC] = []
    @Published var isScanning = false
    @Published var isClearing = false
    @Published var lastScanDate: Date?
    @Published var scanError: String?
    @Published var isDemoMode = false

    private let database = DTCDatabase.shared
    private var demoDTCs: [ActiveDTC] = []

    // MARK: - Demo Mode

    func startDemoMode() {
        isDemoMode = true
        lastScanDate = Date()

        demoDTCs = [
            ActiveDTC(
                code: database.lookup("P0300"),
                detectedAt: Date().addingTimeInterval(-3600),
                freezeFrame: createDemoFreezeFrame(for: "P0300")
            ),
            ActiveDTC(
                code: database.lookup("P0420"),
                detectedAt: Date().addingTimeInterval(-86400),
                freezeFrame: createDemoFreezeFrame(for: "P0420")
            ),
            ActiveDTC(
                code: database.lookup("P0171"),
                detectedAt: Date().addingTimeInterval(-172800),
                freezeFrame: createDemoFreezeFrame(for: "P0171")
            )
        ]

        activeDTCs = demoDTCs
    }

    func stopDemoMode() {
        isDemoMode = false
        activeDTCs = []
        demoDTCs = []
        lastScanDate = nil
        scanError = nil
    }

    private func createDemoFreezeFrame(for code: String) -> FreezeFrameData {
        var ff = FreezeFrameData(dtcCode: code, capturedAt: Date().addingTimeInterval(-3600))
        ff.rpm = Int.random(in: 1500...3500)
        ff.speed = Int.random(in: 40...90)
        ff.coolantTemp = Int.random(in: 85...100)
        ff.engineLoad = Int.random(in: 30...70)
        ff.throttlePosition = Int.random(in: 15...45)
        ff.intakeAirTemp = Int.random(in: 20...40)
        ff.maf = Double.random(in: 5.0...15.0)
        return ff
    }

    // MARK: - Demo Scan/Clear

    func scanForDTCsDemo() {
        guard isDemoMode else { return }

        isScanning = true
        scanError = nil

        // Simulate scanning delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.activeDTCs = self.demoDTCs
            self.lastScanDate = Date()
            self.isScanning = false
        }
    }

    func clearDTCsDemo() {
        guard isDemoMode else { return }

        isClearing = true

        // Simulate clearing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            self.demoDTCs = []
            self.activeDTCs = []
            self.isClearing = false
        }
    }

    // MARK: - DTC Response Parsing

    /// Parse Mode 03 response to extract DTC codes
    /// Response format: "43 01 33 02 17 00 00" or "4301330217"
    func parseDTCResponse(_ response: String) -> [String] {
        var dtcCodes: [String] = []

        let cleanResponse = response.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ">", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Must start with "43" (Mode 03 response)
        guard cleanResponse.hasPrefix("43") else { return [] }

        // Remove the "43" prefix
        var hexData = String(cleanResponse.dropFirst(2))

        // Also remove the byte count if present (some ECUs include it)
        // Format could be "43 XX [DTC pairs]" where XX is count

        // Process DTC pairs (2 bytes = 4 hex chars each)
        while hexData.count >= 4 {
            let dtcHex = String(hexData.prefix(4))
            hexData = String(hexData.dropFirst(4))

            // Skip "0000" which indicates no more codes
            if dtcHex == "0000" { continue }

            if let dtcCode = decodeDTC(from: dtcHex) {
                dtcCodes.append(dtcCode)
            }
        }

        return dtcCodes
    }

    /// Decode a 2-byte DTC into standard format (e.g., "P0300")
    /// First nibble determines category, remaining nibbles are the code number
    private func decodeDTC(from hexPair: String) -> String? {
        guard hexPair.count == 4 else { return nil }

        // Convert to numeric values
        guard let firstByte = UInt8(String(hexPair.prefix(2)), radix: 16),
              let secondByte = UInt8(String(hexPair.suffix(2)), radix: 16) else {
            return nil
        }

        // First nibble (bits 7-6 of first byte) determines category prefix
        let categoryBits = (firstByte >> 6) & 0x03
        let prefix: String
        switch categoryBits {
        case 0: prefix = "P"  // Powertrain
        case 1: prefix = "C"  // Chassis
        case 2: prefix = "B"  // Body
        case 3: prefix = "U"  // Network
        default: prefix = "P"
        }

        // Second nibble (bits 5-4 of first byte) is first digit of code
        let firstDigit = (firstByte >> 4) & 0x03

        // Third nibble (bits 3-0 of first byte) is second digit
        let secondDigit = firstByte & 0x0F

        // Fourth and fifth nibbles are from second byte
        let thirdDigit = (secondByte >> 4) & 0x0F
        let fourthDigit = secondByte & 0x0F

        // Format as standard DTC code
        return String(format: "%@%X%X%X%X", prefix, firstDigit, secondDigit, thirdDigit, fourthDigit)
    }

    /// Parse Mode 02 freeze frame response
    func parseFreezeFrameResponse(_ response: String, for dtcCode: String) -> FreezeFrameData? {
        var freezeFrame = FreezeFrameData(dtcCode: dtcCode)

        let cleanResponse = response.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ">", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Must start with "42" (Mode 02 response)
        guard cleanResponse.hasPrefix("42") else { return nil }

        // Parse based on PID in response
        let hexData = String(cleanResponse.dropFirst(2))

        // Get PID and data
        guard hexData.count >= 4 else { return nil }
        let pid = String(hexData.prefix(2))
        let dataBytes = String(hexData.dropFirst(2))

        switch pid {
        case "0C": // RPM
            if dataBytes.count >= 4,
               let a = UInt16(String(dataBytes.prefix(2)), radix: 16),
               let b = UInt16(String(dataBytes.dropFirst(2).prefix(2)), radix: 16) {
                freezeFrame.rpm = Int((a * 256 + b) / 4)
            }
        case "0D": // Speed
            if let a = UInt16(String(dataBytes.prefix(2)), radix: 16) {
                freezeFrame.speed = Int(a)
            }
        case "05": // Coolant Temp
            if let a = Int16(String(dataBytes.prefix(2)), radix: 16) {
                freezeFrame.coolantTemp = Int(a) - 40
            }
        case "04": // Engine Load
            if let a = UInt16(String(dataBytes.prefix(2)), radix: 16) {
                freezeFrame.engineLoad = Int(a) * 100 / 255
            }
        case "11": // Throttle Position
            if let a = UInt16(String(dataBytes.prefix(2)), radix: 16) {
                freezeFrame.throttlePosition = Int(a) * 100 / 255
            }
        case "0F": // Intake Air Temp
            if let a = Int16(String(dataBytes.prefix(2)), radix: 16) {
                freezeFrame.intakeAirTemp = Int(a) - 40
            }
        case "10": // MAF
            if dataBytes.count >= 4,
               let a = UInt16(String(dataBytes.prefix(2)), radix: 16),
               let b = UInt16(String(dataBytes.dropFirst(2).prefix(2)), radix: 16) {
                freezeFrame.maf = Double(a * 256 + b) / 100.0
            }
        default:
            break
        }

        return freezeFrame
    }

    // MARK: - Convert DTC codes to ActiveDTC objects

    func createActiveDTCs(from codes: [String]) -> [ActiveDTC] {
        return codes.map { code in
            ActiveDTC(
                code: database.lookup(code),
                detectedAt: Date()
            )
        }
    }

    // MARK: - Public API for real OBD connection

    func processReadDTCsResponse(_ response: String) {
        let codes = parseDTCResponse(response)
        DispatchQueue.main.async {
            self.activeDTCs = self.createActiveDTCs(from: codes)
            self.lastScanDate = Date()
            self.isScanning = false
        }
    }

    func processClearDTCsResponse(_ response: String) {
        let cleanResponse = response.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        DispatchQueue.main.async {
            if cleanResponse.hasPrefix("44") {
                // Success
                self.activeDTCs = []
                self.scanError = nil
            } else if cleanResponse.hasPrefix("7F") {
                // Error
                self.scanError = String(localized: "Failed to clear codes. Try again.")
            }
            self.isClearing = false
        }
    }

    func handleNoData() {
        DispatchQueue.main.async {
            self.activeDTCs = []
            self.lastScanDate = Date()
            self.isScanning = false
            self.scanError = nil
        }
    }

    func handleError(_ message: String) {
        DispatchQueue.main.async {
            self.scanError = message
            self.isScanning = false
            self.isClearing = false
        }
    }
}
