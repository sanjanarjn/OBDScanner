import SwiftUI

enum OBDParameterType: String, CaseIterable, Identifiable {
    case rpm
    case speed
    case coolantTemp
    case engineLoad
    case throttlePosition
    case fuelLevel
    case intakeAirTemp
    case maf
    case timing

    var id: String { rawValue }

    var pid: String {
        switch self {
        case .rpm: return "010C"
        case .speed: return "010D"
        case .coolantTemp: return "0105"
        case .engineLoad: return "0104"
        case .throttlePosition: return "0111"
        case .fuelLevel: return "012F"
        case .intakeAirTemp: return "010F"
        case .maf: return "0110"
        case .timing: return "010E"
        }
    }

    var title: String {
        switch self {
        case .rpm: return "Engine RPM"
        case .speed: return "Speed"
        case .coolantTemp: return "Coolant Temp"
        case .engineLoad: return "Engine Load"
        case .throttlePosition: return "Throttle Position"
        case .fuelLevel: return "Fuel Level"
        case .intakeAirTemp: return "Intake Air Temp"
        case .maf: return "Air Flow Rate"
        case .timing: return "Timing Advance"
        }
    }

    var iconName: String {
        switch self {
        case .rpm: return "gauge.high"
        case .speed: return "speedometer"
        case .coolantTemp: return "thermometer"
        case .engineLoad: return "engine.combustion"
        case .throttlePosition: return "slider.horizontal.3"
        case .fuelLevel: return "fuelpump"
        case .intakeAirTemp: return "wind"
        case .maf: return "air.conditioner.horizontal"
        case .timing: return "timer"
        }
    }

    var unit: String {
        switch self {
        case .rpm: return "RPM"
        case .speed: return "km/h"
        case .coolantTemp: return "°C"
        case .engineLoad: return "%"
        case .throttlePosition: return "%"
        case .fuelLevel: return "%"
        case .intakeAirTemp: return "°C"
        case .maf: return "g/s"
        case .timing: return "°"
        }
    }

    var description: String {
        switch self {
        case .rpm:
            return "Engine RPM (Revolutions Per Minute) indicates how fast your engine is turning. Normal idle is typically 600-1000 RPM. Higher RPM means the engine is working harder."
        case .speed:
            return "Vehicle speed as reported by the vehicle's speed sensor. This is the actual speed your car is traveling."
        case .coolantTemp:
            return "Engine coolant temperature shows how hot your engine is running. Normal operating temperature is typically 85-105°C. If it's too high, your engine may be overheating."
        case .engineLoad:
            return "Calculated engine load shows what percentage of maximum available torque is being used. Higher values indicate the engine is working harder."
        case .throttlePosition:
            return "Throttle position shows how far the accelerator pedal is pressed. 0% means idle, 100% means full throttle."
        case .fuelLevel:
            return "Fuel tank level indicates how much fuel remains in your tank as a percentage of the total capacity."
        case .intakeAirTemp:
            return "Intake air temperature measures the temperature of air entering the engine. Cooler air is denser and can improve performance."
        case .maf:
            return "Mass Air Flow (MAF) measures the amount of air entering the engine in grams per second. This helps the engine computer determine the correct fuel mixture."
        case .timing:
            return "Timing advance shows how many degrees before Top Dead Center (TDC) the spark plug fires. Advanced timing can improve performance but too much can cause engine knock."
        }
    }

    var normalRange: String {
        switch self {
        case .rpm: return "Idle: 600-1000 RPM\nDriving: 1500-3000 RPM"
        case .speed: return "Varies based on driving"
        case .coolantTemp: return "Normal: 85-105°C\nWarning: >110°C"
        case .engineLoad: return "Idle: 20-30%\nCruising: 30-50%\nAccelerating: 50-90%"
        case .throttlePosition: return "Idle: 0-5%\nCruising: 10-20%\nFull throttle: 100%"
        case .fuelLevel: return "Refill recommended: <25%"
        case .intakeAirTemp: return "Normal: 10-50°C"
        case .maf: return "Idle: 2-7 g/s\nCruising: 5-15 g/s"
        case .timing: return "Typical: -10° to +40°"
        }
    }

    var tips: String {
        switch self {
        case .rpm:
            return "• Keep RPM below 3000 for better fuel economy\n• High RPM at idle may indicate a problem\n• Shift gears around 2000-2500 RPM for efficiency"
        case .speed:
            return "• Maintain steady speed for better fuel economy\n• Use cruise control on highways\n• Avoid rapid acceleration and braking"
        case .coolantTemp:
            return "• Let engine warm up before driving hard\n• Check coolant levels if temperature is too high\n• Turn off AC if engine is overheating"
        case .engineLoad:
            return "• Lower load = better fuel economy\n• High load during cruising may indicate a problem\n• Remove unnecessary weight from vehicle"
        case .throttlePosition:
            return "• Gentle acceleration saves fuel\n• Smooth throttle control improves comfort\n• Avoid sudden throttle changes"
        case .fuelLevel:
            return "• Keep tank above 25% to protect fuel pump\n• Fill up when convenient, don't wait for empty\n• Track fuel consumption to detect issues"
        case .intakeAirTemp:
            return "• High intake temps reduce performance\n• Cold air intake can help in hot weather\n• High temps normal after engine shutdown"
        case .maf:
            return "• Clean MAF sensor if readings seem erratic\n• Low readings may indicate air leaks\n• Consistent readings indicate good engine health"
        case .timing:
            return "• Engine computer adjusts automatically\n• Retarded timing may indicate knock detection\n• Use recommended fuel octane rating"
        }
    }

    func parseValue(from response: String) -> String? {
        // Clean up response - remove extra whitespace, convert to uppercase
        let cleanResponse = response.uppercased().replacingOccurrences(of: ">", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle responses without spaces (e.g., "410D00" instead of "41 0D 00")
        var hexString = cleanResponse

        // If the response doesn't have spaces, we need to parse it differently
        if !hexString.contains(" ") {
            // Make sure we have at least 6 characters for a valid response (41XXYY)
            guard hexString.count >= 6 else { return nil }

            // Check if response starts with "41" (positive response)
            guard hexString.hasPrefix("41") else { return nil }

            // Get the PID part (characters 2-3)
            let pidPart = String(hexString.dropFirst(2).prefix(2))
            let expectedPID = String(pid.dropFirst(2)).uppercased()

            guard pidPart == expectedPID else { return nil }

            // Extract data bytes after the PID
            let dataStart = hexString.index(hexString.startIndex, offsetBy: 4)
            let dataBytes = String(hexString[dataStart...])

            // Parse based on parameter type
            switch self {
            case .rpm:
                // Formula: ((A*256)+B)/4 - needs 4 hex chars (2 bytes)
                guard dataBytes.count >= 4 else { return nil }
                let aStr = String(dataBytes.prefix(2))
                let bStr = String(dataBytes.dropFirst(2).prefix(2))
                if let A = UInt16(aStr, radix: 16),
                   let B = UInt16(bStr, radix: 16) {
                    let value = ((A * 256) + B) / 4
                    return "\(value)"
                }

            case .speed:
                // Formula: A - needs 2 hex chars (1 byte)
                guard dataBytes.count >= 2 else { return nil }
                let aStr = String(dataBytes.prefix(2))
                if let A = UInt16(aStr, radix: 16) {
                    return "\(A)"
                }

            case .coolantTemp, .intakeAirTemp:
                // Formula: A - 40 - needs 2 hex chars (1 byte)
                guard dataBytes.count >= 2 else { return nil }
                let aStr = String(dataBytes.prefix(2))
                if let A = Int16(aStr, radix: 16) {
                    let value = Int(A) - 40
                    return "\(value)"
                }

            case .engineLoad, .throttlePosition, .fuelLevel:
                // Formula: A * 100 / 255 - needs 2 hex chars (1 byte)
                guard dataBytes.count >= 2 else { return nil }
                let aStr = String(dataBytes.prefix(2))
                if let A = UInt16(aStr, radix: 16) {
                    let value = (Int(A) * 100) / 255
                    return "\(value)"
                }

            case .maf:
                // Formula: ((A*256)+B) / 100 - needs 4 hex chars (2 bytes)
                guard dataBytes.count >= 4 else { return nil }
                let aStr = String(dataBytes.prefix(2))
                let bStr = String(dataBytes.dropFirst(2).prefix(2))
                if let A = UInt16(aStr, radix: 16),
                   let B = UInt16(bStr, radix: 16) {
                    let value = Double((A * 256) + B) / 100.0
                    return String(format: "%.1f", value)
                }

            case .timing:
                // Formula: (A - 128) / 2 - needs 2 hex chars (1 byte)
                guard dataBytes.count >= 2 else { return nil }
                let aStr = String(dataBytes.prefix(2))
                if let A = Int16(aStr, radix: 16) {
                    let value = Double(Int(A) - 128) / 2.0
                    return String(format: "%.1f", value)
                }
            }

            return nil
        }

        // Original space-separated parsing
        let parts = cleanResponse.split(separator: " ").map { String($0) }
        guard parts.count >= 3 else { return nil }

        // Check if response matches our PID (response is "41 XX ..." where XX is our PID without "01")
        let expectedPIDResponse = String(pid.dropFirst(2)).uppercased()
        guard parts.count >= 2 && parts[0] == "41" && parts[1] == expectedPIDResponse else { return nil }

        switch self {
        case .rpm:
            // Formula: ((A*256)+B)/4
            if parts.count >= 4,
               let A = UInt16(parts[2], radix: 16),
               let B = UInt16(parts[3], radix: 16) {
                let value = ((A * 256) + B) / 4
                return "\(value)"
            }

        case .speed:
            // Formula: A
            if let A = UInt16(parts[2], radix: 16) {
                return "\(A)"
            }

        case .coolantTemp, .intakeAirTemp:
            // Formula: A - 40
            if let A = Int16(parts[2], radix: 16) {
                let value = Int(A) - 40
                return "\(value)"
            }

        case .engineLoad, .throttlePosition, .fuelLevel:
            // Formula: A * 100 / 255
            if let A = UInt16(parts[2], radix: 16) {
                let value = (Int(A) * 100) / 255
                return "\(value)"
            }

        case .maf:
            // Formula: ((A*256)+B) / 100
            if parts.count >= 4,
               let A = UInt16(parts[2], radix: 16),
               let B = UInt16(parts[3], radix: 16) {
                let value = Double((A * 256) + B) / 100.0
                return String(format: "%.1f", value)
            }

        case .timing:
            // Formula: (A - 128) / 2
            if let A = Int16(parts[2], radix: 16) {
                let value = Double(Int(A) - 128) / 2.0
                return String(format: "%.1f", value)
            }
        }

        return nil
    }
}

struct OBDParameterData: Identifiable {
    let id = UUID()
    let type: OBDParameterType
    var value: String
    var lastUpdated: Date

    var displayValue: String {
        if value == "N/A" {
            return "N/A"
        }
        return "\(value) \(type.unit)"
    }
}
