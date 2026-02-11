import Foundation

class DTCDatabase {
    static let shared = DTCDatabase()

    private var codes: [String: DTCCode] = [:]
    private var isLoaded = false

    private init() {
        loadDatabase()
    }

    func lookup(_ code: String) -> DTCCode {
        let upperCode = code.uppercased()
        if let dtc = codes[upperCode] {
            return dtc
        }
        return DTCCode.genericCode(for: upperCode)
    }

    func allCodes() -> [DTCCode] {
        return Array(codes.values).sorted { $0.id < $1.id }
    }

    private func loadDatabase() {
        guard !isLoaded else { return }

        if let url = Bundle.main.url(forResource: "dtc_database", withExtension: "json"),
           let data = try? Data(contentsOf: url) {
            do {
                let decoder = JSONDecoder()
                let wrapper = try decoder.decode(DTCDatabaseWrapper.self, from: data)
                for dtc in wrapper.codes {
                    codes[dtc.id.uppercased()] = dtc
                }
                isLoaded = true
                print("Loaded \(codes.count) DTC codes from database")
            } catch {
                print("Failed to decode DTC database: \(error)")
                loadBuiltInCodes()
            }
        } else {
            print("DTC database file not found, using built-in codes")
            loadBuiltInCodes()
        }
    }

    private func loadBuiltInCodes() {
        let builtIn = Self.commonDTCCodes
        for dtc in builtIn {
            codes[dtc.id.uppercased()] = dtc
        }
        isLoaded = true
        print("Loaded \(codes.count) built-in DTC codes")
    }

    // Common DTC codes built into the app
    static let commonDTCCodes: [DTCCode] = [
        // Powertrain - Fuel and Air Metering
        DTCCode(id: "P0100", description: "Mass or Volume Air Flow Circuit Malfunction", severity: .warning,
                possibleCauses: ["Faulty MAF sensor", "Air leak between MAF and throttle body", "Dirty air filter", "Damaged wiring"],
                symptoms: ["Check Engine Light on", "Poor fuel economy", "Rough idle", "Hesitation"]),

        DTCCode(id: "P0101", description: "Mass or Volume Air Flow Circuit Range/Performance", severity: .warning,
                possibleCauses: ["Dirty MAF sensor", "Vacuum leak", "Faulty MAF sensor", "Restricted air filter"],
                symptoms: ["Poor acceleration", "Black smoke from exhaust", "Rough idle"]),

        DTCCode(id: "P0102", description: "Mass or Volume Air Flow Circuit Low Input", severity: .warning,
                possibleCauses: ["Faulty MAF sensor", "Open or short in wiring", "Poor electrical connection"],
                symptoms: ["Engine stalling", "Hard starting", "Rough idle"]),

        DTCCode(id: "P0103", description: "Mass or Volume Air Flow Circuit High Input", severity: .warning,
                possibleCauses: ["Faulty MAF sensor", "Short to voltage in circuit", "Contaminated MAF sensor"],
                symptoms: ["Rich running condition", "Black smoke", "Poor fuel economy"]),

        DTCCode(id: "P0110", description: "Intake Air Temperature Sensor Circuit Malfunction", severity: .info,
                possibleCauses: ["Faulty IAT sensor", "Damaged wiring", "Poor connection"],
                symptoms: ["Check Engine Light on", "Hard starting in cold weather"]),

        DTCCode(id: "P0115", description: "Engine Coolant Temperature Circuit Malfunction", severity: .warning,
                possibleCauses: ["Faulty ECT sensor", "Open or short in wiring", "Faulty thermostat"],
                symptoms: ["Poor fuel economy", "Engine overheating", "Hard starting"]),

        DTCCode(id: "P0120", description: "Throttle Position Sensor Circuit Malfunction", severity: .warning,
                possibleCauses: ["Faulty TPS", "Damaged wiring", "Poor throttle body ground"],
                symptoms: ["Erratic idle", "Hesitation", "Poor acceleration"]),

        DTCCode(id: "P0130", description: "O2 Sensor Circuit Malfunction (Bank 1 Sensor 1)", severity: .warning,
                possibleCauses: ["Faulty O2 sensor", "Exhaust leak", "Damaged wiring", "Rich/lean condition"],
                symptoms: ["Poor fuel economy", "Rough idle", "Failed emissions test"]),

        DTCCode(id: "P0133", description: "O2 Sensor Circuit Slow Response (Bank 1 Sensor 1)", severity: .warning,
                possibleCauses: ["Aging O2 sensor", "Exhaust leak", "Fuel pressure issue"],
                symptoms: ["Poor fuel economy", "Sluggish response", "Failed emissions"]),

        DTCCode(id: "P0171", description: "System Too Lean (Bank 1)", severity: .warning,
                possibleCauses: ["Vacuum leak", "Faulty MAF sensor", "Weak fuel pump", "Clogged fuel injectors"],
                symptoms: ["Rough idle", "Hesitation", "Poor acceleration", "Misfires"]),

        DTCCode(id: "P0172", description: "System Too Rich (Bank 1)", severity: .warning,
                possibleCauses: ["Faulty O2 sensor", "Leaking fuel injector", "High fuel pressure", "Faulty MAF"],
                symptoms: ["Black smoke", "Poor fuel economy", "Rough idle", "Spark plug fouling"]),

        // Ignition System and Misfires
        DTCCode(id: "P0300", description: "Random/Multiple Cylinder Misfire Detected", severity: .critical,
                possibleCauses: ["Worn spark plugs", "Faulty ignition coils", "Vacuum leak", "Low fuel pressure", "Faulty fuel injectors"],
                symptoms: ["Check Engine Light flashing", "Engine shaking", "Poor acceleration", "Increased emissions"]),

        DTCCode(id: "P0301", description: "Cylinder 1 Misfire Detected", severity: .critical,
                possibleCauses: ["Faulty spark plug in cylinder 1", "Faulty ignition coil", "Fuel injector issue", "Low compression"],
                symptoms: ["Rough idle", "Loss of power", "Increased emissions"]),

        DTCCode(id: "P0302", description: "Cylinder 2 Misfire Detected", severity: .critical,
                possibleCauses: ["Faulty spark plug in cylinder 2", "Faulty ignition coil", "Fuel injector issue", "Low compression"],
                symptoms: ["Rough idle", "Loss of power", "Increased emissions"]),

        DTCCode(id: "P0303", description: "Cylinder 3 Misfire Detected", severity: .critical,
                possibleCauses: ["Faulty spark plug in cylinder 3", "Faulty ignition coil", "Fuel injector issue", "Low compression"],
                symptoms: ["Rough idle", "Loss of power", "Increased emissions"]),

        DTCCode(id: "P0304", description: "Cylinder 4 Misfire Detected", severity: .critical,
                possibleCauses: ["Faulty spark plug in cylinder 4", "Faulty ignition coil", "Fuel injector issue", "Low compression"],
                symptoms: ["Rough idle", "Loss of power", "Increased emissions"]),

        DTCCode(id: "P0305", description: "Cylinder 5 Misfire Detected", severity: .critical,
                possibleCauses: ["Faulty spark plug in cylinder 5", "Faulty ignition coil", "Fuel injector issue", "Low compression"],
                symptoms: ["Rough idle", "Loss of power", "Increased emissions"]),

        DTCCode(id: "P0306", description: "Cylinder 6 Misfire Detected", severity: .critical,
                possibleCauses: ["Faulty spark plug in cylinder 6", "Faulty ignition coil", "Fuel injector issue", "Low compression"],
                symptoms: ["Rough idle", "Loss of power", "Increased emissions"]),

        // Catalyst System
        DTCCode(id: "P0420", description: "Catalyst System Efficiency Below Threshold (Bank 1)", severity: .warning,
                possibleCauses: ["Failing catalytic converter", "Faulty O2 sensor", "Exhaust leak", "Engine misfire damage"],
                symptoms: ["Check Engine Light on", "Reduced fuel economy", "Failed emissions test", "Sulfur smell"]),

        DTCCode(id: "P0430", description: "Catalyst System Efficiency Below Threshold (Bank 2)", severity: .warning,
                possibleCauses: ["Failing catalytic converter", "Faulty O2 sensor", "Exhaust leak"],
                symptoms: ["Check Engine Light on", "Failed emissions test", "Sulfur smell"]),

        // EVAP System
        DTCCode(id: "P0440", description: "Evaporative Emission Control System Malfunction", severity: .info,
                possibleCauses: ["Loose gas cap", "EVAP canister issue", "Faulty purge valve", "Leak in EVAP system"],
                symptoms: ["Check Engine Light on", "Fuel odor"]),

        DTCCode(id: "P0442", description: "Evaporative Emission System Leak Detected (Small Leak)", severity: .info,
                possibleCauses: ["Loose or damaged gas cap", "Small leak in EVAP hose", "Faulty purge valve"],
                symptoms: ["Check Engine Light on", "Slight fuel odor"]),

        DTCCode(id: "P0446", description: "Evaporative Emission System Vent Control Circuit", severity: .info,
                possibleCauses: ["Faulty vent valve", "Blockage in vent line", "Wiring issue"],
                symptoms: ["Check Engine Light on", "Difficulty refueling"]),

        DTCCode(id: "P0455", description: "Evaporative Emission System Leak Detected (Large Leak)", severity: .warning,
                possibleCauses: ["Missing or loose gas cap", "Cracked EVAP hose", "Faulty purge valve"],
                symptoms: ["Check Engine Light on", "Strong fuel odor"]),

        // EGR System
        DTCCode(id: "P0401", description: "Exhaust Gas Recirculation Flow Insufficient", severity: .warning,
                possibleCauses: ["Clogged EGR passages", "Faulty EGR valve", "Carbon buildup"],
                symptoms: ["Engine knock", "Rough idle", "Failed emissions test"]),

        DTCCode(id: "P0402", description: "Exhaust Gas Recirculation Flow Excessive", severity: .warning,
                possibleCauses: ["Stuck open EGR valve", "Vacuum leak to EGR", "Faulty DPFE sensor"],
                symptoms: ["Rough idle", "Stalling", "Poor acceleration"]),

        // Vehicle Speed and Transmission
        DTCCode(id: "P0500", description: "Vehicle Speed Sensor Malfunction", severity: .warning,
                possibleCauses: ["Faulty VSS", "Damaged wiring", "Faulty instrument cluster"],
                symptoms: ["Speedometer not working", "Transmission shifting issues", "ABS light on"]),

        DTCCode(id: "P0505", description: "Idle Air Control System Malfunction", severity: .warning,
                possibleCauses: ["Faulty IAC valve", "Vacuum leak", "Dirty throttle body", "Wiring issue"],
                symptoms: ["Erratic idle", "Stalling", "High idle"]),

        DTCCode(id: "P0700", description: "Transmission Control System Malfunction", severity: .warning,
                possibleCauses: ["Transmission issue detected", "Low transmission fluid", "Solenoid failure"],
                symptoms: ["Check Engine Light on", "Transmission warning light", "Shifting problems"]),

        DTCCode(id: "P0715", description: "Input/Turbine Speed Sensor Circuit Malfunction", severity: .warning,
                possibleCauses: ["Faulty input speed sensor", "Damaged wiring", "Low transmission fluid"],
                symptoms: ["Harsh shifting", "Transmission slipping", "No speedometer reading"]),

        // Body Codes
        DTCCode(id: "B0001", description: "Driver Frontal Stage 1 Deployment Control", severity: .critical,
                possibleCauses: ["Airbag system malfunction", "Faulty clockspring", "Wiring issue"],
                symptoms: ["Airbag warning light on", "Airbag may not deploy"]),

        DTCCode(id: "B0100", description: "Electronic Frontal Sensor 1 Performance", severity: .critical,
                possibleCauses: ["Damaged crash sensor", "Wiring issue", "Module failure"],
                symptoms: ["Airbag warning light on"]),

        // Chassis Codes
        DTCCode(id: "C0035", description: "Left Front Wheel Speed Sensor Circuit", severity: .warning,
                possibleCauses: ["Faulty wheel speed sensor", "Damaged wiring", "Damaged tone ring"],
                symptoms: ["ABS light on", "Traction control disabled"]),

        DTCCode(id: "C0040", description: "Right Front Wheel Speed Sensor Circuit", severity: .warning,
                possibleCauses: ["Faulty wheel speed sensor", "Damaged wiring", "Damaged tone ring"],
                symptoms: ["ABS light on", "Traction control disabled"]),

        DTCCode(id: "C0045", description: "Left Rear Wheel Speed Sensor Circuit", severity: .warning,
                possibleCauses: ["Faulty wheel speed sensor", "Damaged wiring", "Damaged tone ring"],
                symptoms: ["ABS light on", "Traction control disabled"]),

        DTCCode(id: "C0050", description: "Right Rear Wheel Speed Sensor Circuit", severity: .warning,
                possibleCauses: ["Faulty wheel speed sensor", "Damaged wiring", "Damaged tone ring"],
                symptoms: ["ABS light on", "Traction control disabled"]),

        // Network Codes
        DTCCode(id: "U0001", description: "High Speed CAN Communication Bus", severity: .warning,
                possibleCauses: ["CAN bus wiring issue", "Faulty module", "Short circuit"],
                symptoms: ["Multiple warning lights", "Communication errors between modules"]),

        DTCCode(id: "U0100", description: "Lost Communication With ECM/PCM", severity: .critical,
                possibleCauses: ["Faulty ECM/PCM", "CAN bus wiring issue", "Power/ground issue"],
                symptoms: ["No start condition", "Multiple DTCs", "Limp mode"]),

        DTCCode(id: "U0101", description: "Lost Communication With TCM", severity: .warning,
                possibleCauses: ["Faulty TCM", "CAN bus wiring issue", "TCM power issue"],
                symptoms: ["Transmission in limp mode", "No shifting"]),

        DTCCode(id: "U0121", description: "Lost Communication With Anti-Lock Brake System Module", severity: .warning,
                possibleCauses: ["Faulty ABS module", "CAN bus wiring issue", "ABS fuse blown"],
                symptoms: ["ABS light on", "ABS not functional"]),

        DTCCode(id: "U0140", description: "Lost Communication With Body Control Module", severity: .warning,
                possibleCauses: ["Faulty BCM", "CAN bus wiring issue", "BCM power issue"],
                symptoms: ["Various electrical issues", "Warning lights"]),
    ]
}

// MARK: - JSON Decoding Support

private struct DTCDatabaseWrapper: Codable {
    let version: String
    let codes: [DTCCode]
}
