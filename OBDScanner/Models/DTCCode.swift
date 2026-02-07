import SwiftUI

// MARK: - DTC Severity

enum DTCSeverity: String, Codable, CaseIterable {
    case critical
    case warning
    case info

    var color: Color {
        switch self {
        case .critical: return .red
        case .warning: return .orange
        case .info: return .yellow
        }
    }

    var iconName: String {
        switch self {
        case .critical: return "exclamationmark.octagon.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .info: return "info.circle.fill"
        }
    }
}

// MARK: - DTC Category

enum DTCCategory: String, CaseIterable {
    case powertrain = "P"
    case body = "B"
    case chassis = "C"
    case network = "U"

    var displayName: String {
        switch self {
        case .powertrain: return "Powertrain"
        case .body: return "Body"
        case .chassis: return "Chassis"
        case .network: return "Network"
        }
    }

    var description: String {
        switch self {
        case .powertrain: return "Engine, transmission, and emissions systems"
        case .body: return "Body systems like airbags, A/C, and lighting"
        case .chassis: return "ABS, steering, and suspension systems"
        case .network: return "CAN bus and module communication"
        }
    }
}

// MARK: - DTC Code

struct DTCCode: Identifiable, Codable, Hashable {
    let id: String
    let description: String
    let severity: DTCSeverity
    let possibleCauses: [String]
    let symptoms: [String]

    var category: DTCCategory {
        guard let first = id.first else { return .powertrain }
        switch first {
        case "P": return .powertrain
        case "B": return .body
        case "C": return .chassis
        case "U": return .network
        default: return .powertrain
        }
    }

    var isGeneric: Bool {
        guard id.count >= 2 else { return true }
        let secondChar = id[id.index(id.startIndex, offsetBy: 1)]
        return secondChar == "0" || secondChar == "2"
    }

    var codeNumber: String {
        guard id.count >= 2 else { return id }
        return String(id.dropFirst())
    }

    static func genericCode(for id: String) -> DTCCode {
        let category: DTCCategory
        if let first = id.first {
            switch first {
            case "P": category = .powertrain
            case "B": category = .body
            case "C": category = .chassis
            case "U": category = .network
            default: category = .powertrain
            }
        } else {
            category = .powertrain
        }

        return DTCCode(
            id: id,
            description: "Unknown \(category.displayName) code",
            severity: .warning,
            possibleCauses: ["Consult a professional mechanic for diagnosis"],
            symptoms: ["Check Engine Light may be on"]
        )
    }
}

// MARK: - Active DTC

struct ActiveDTC: Identifiable {
    let id: UUID
    let code: DTCCode
    let detectedAt: Date
    var freezeFrame: FreezeFrameData?

    init(code: DTCCode, detectedAt: Date = Date(), freezeFrame: FreezeFrameData? = nil) {
        self.id = UUID()
        self.code = code
        self.detectedAt = detectedAt
        self.freezeFrame = freezeFrame
    }
}

// MARK: - Freeze Frame Data

struct FreezeFrameData: Identifiable {
    let id: UUID
    let dtcCode: String
    let capturedAt: Date

    var rpm: Int?
    var speed: Int?
    var coolantTemp: Int?
    var engineLoad: Int?
    var throttlePosition: Int?
    var fuelLevel: Int?
    var intakeAirTemp: Int?
    var maf: Double?
    var timingAdvance: Double?

    init(dtcCode: String, capturedAt: Date = Date()) {
        self.id = UUID()
        self.dtcCode = dtcCode
        self.capturedAt = capturedAt
    }

    var hasData: Bool {
        rpm != nil || speed != nil || coolantTemp != nil || engineLoad != nil ||
        throttlePosition != nil || intakeAirTemp != nil || maf != nil
    }
}
