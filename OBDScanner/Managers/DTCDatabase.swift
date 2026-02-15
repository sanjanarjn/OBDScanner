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
        DTCCode(id: "P0100", description: String(localized: "Mass or Volume Air Flow Circuit Malfunction"), severity: .warning,
                possibleCauses: [String(localized: "Faulty MAF sensor"), String(localized: "Air leak between MAF and throttle body"), String(localized: "Dirty air filter"), String(localized: "Damaged wiring")],
                symptoms: [String(localized: "Check Engine Light on"), String(localized: "Poor fuel economy"), String(localized: "Rough idle"), String(localized: "Hesitation")]),

        DTCCode(id: "P0101", description: String(localized: "Mass or Volume Air Flow Circuit Range/Performance"), severity: .warning,
                possibleCauses: [String(localized: "Dirty MAF sensor"), String(localized: "Vacuum leak"), String(localized: "Faulty MAF sensor"), String(localized: "Restricted air filter")],
                symptoms: [String(localized: "Poor acceleration"), String(localized: "Black smoke from exhaust"), String(localized: "Rough idle")]),

        DTCCode(id: "P0102", description: String(localized: "Mass or Volume Air Flow Circuit Low Input"), severity: .warning,
                possibleCauses: [String(localized: "Faulty MAF sensor"), String(localized: "Open or short in wiring"), String(localized: "Poor electrical connection")],
                symptoms: [String(localized: "Engine stalling"), String(localized: "Hard starting"), String(localized: "Rough idle")]),

        DTCCode(id: "P0103", description: String(localized: "Mass or Volume Air Flow Circuit High Input"), severity: .warning,
                possibleCauses: [String(localized: "Faulty MAF sensor"), String(localized: "Short to voltage in circuit"), String(localized: "Contaminated MAF sensor")],
                symptoms: [String(localized: "Rich running condition"), String(localized: "Black smoke"), String(localized: "Poor fuel economy")]),

        DTCCode(id: "P0110", description: String(localized: "Intake Air Temperature Sensor Circuit Malfunction"), severity: .info,
                possibleCauses: [String(localized: "Faulty IAT sensor"), String(localized: "Damaged wiring"), String(localized: "Poor connection")],
                symptoms: [String(localized: "Check Engine Light on"), String(localized: "Hard starting in cold weather")]),

        DTCCode(id: "P0115", description: String(localized: "Engine Coolant Temperature Circuit Malfunction"), severity: .warning,
                possibleCauses: [String(localized: "Faulty ECT sensor"), String(localized: "Open or short in wiring"), String(localized: "Faulty thermostat")],
                symptoms: [String(localized: "Poor fuel economy"), String(localized: "Engine overheating"), String(localized: "Hard starting")]),

        DTCCode(id: "P0120", description: String(localized: "Throttle Position Sensor Circuit Malfunction"), severity: .warning,
                possibleCauses: [String(localized: "Faulty TPS"), String(localized: "Damaged wiring"), String(localized: "Poor throttle body ground")],
                symptoms: [String(localized: "Erratic idle"), String(localized: "Hesitation"), String(localized: "Poor acceleration")]),

        DTCCode(id: "P0130", description: String(localized: "O2 Sensor Circuit Malfunction (Bank 1 Sensor 1)"), severity: .warning,
                possibleCauses: [String(localized: "Faulty O2 sensor"), String(localized: "Exhaust leak"), String(localized: "Damaged wiring"), String(localized: "Rich/lean condition")],
                symptoms: [String(localized: "Poor fuel economy"), String(localized: "Rough idle"), String(localized: "Failed emissions test")]),

        DTCCode(id: "P0133", description: String(localized: "O2 Sensor Circuit Slow Response (Bank 1 Sensor 1)"), severity: .warning,
                possibleCauses: [String(localized: "Aging O2 sensor"), String(localized: "Exhaust leak"), String(localized: "Fuel pressure issue")],
                symptoms: [String(localized: "Poor fuel economy"), String(localized: "Sluggish response"), String(localized: "Failed emissions")]),

        DTCCode(id: "P0171", description: String(localized: "System Too Lean (Bank 1)"), severity: .warning,
                possibleCauses: [String(localized: "Vacuum leak"), String(localized: "Faulty MAF sensor"), String(localized: "Weak fuel pump"), String(localized: "Clogged fuel injectors")],
                symptoms: [String(localized: "Rough idle"), String(localized: "Hesitation"), String(localized: "Poor acceleration"), String(localized: "Misfires")]),

        DTCCode(id: "P0172", description: String(localized: "System Too Rich (Bank 1)"), severity: .warning,
                possibleCauses: [String(localized: "Faulty O2 sensor"), String(localized: "Leaking fuel injector"), String(localized: "High fuel pressure"), String(localized: "Faulty MAF")],
                symptoms: [String(localized: "Black smoke"), String(localized: "Poor fuel economy"), String(localized: "Rough idle"), String(localized: "Spark plug fouling")]),

        // Ignition System and Misfires
        DTCCode(id: "P0300", description: String(localized: "Random/Multiple Cylinder Misfire Detected"), severity: .critical,
                possibleCauses: [String(localized: "Worn spark plugs"), String(localized: "Faulty ignition coils"), String(localized: "Vacuum leak"), String(localized: "Low fuel pressure"), String(localized: "Faulty fuel injectors")],
                symptoms: [String(localized: "Check Engine Light flashing"), String(localized: "Engine shaking"), String(localized: "Poor acceleration"), String(localized: "Increased emissions")]),

        DTCCode(id: "P0301", description: String(localized: "Cylinder 1 Misfire Detected"), severity: .critical,
                possibleCauses: [String(localized: "Faulty spark plug in cylinder 1"), String(localized: "Faulty ignition coil"), String(localized: "Fuel injector issue"), String(localized: "Low compression")],
                symptoms: [String(localized: "Rough idle"), String(localized: "Loss of power"), String(localized: "Increased emissions")]),

        DTCCode(id: "P0302", description: String(localized: "Cylinder 2 Misfire Detected"), severity: .critical,
                possibleCauses: [String(localized: "Faulty spark plug in cylinder 2"), String(localized: "Faulty ignition coil"), String(localized: "Fuel injector issue"), String(localized: "Low compression")],
                symptoms: [String(localized: "Rough idle"), String(localized: "Loss of power"), String(localized: "Increased emissions")]),

        DTCCode(id: "P0303", description: String(localized: "Cylinder 3 Misfire Detected"), severity: .critical,
                possibleCauses: [String(localized: "Faulty spark plug in cylinder 3"), String(localized: "Faulty ignition coil"), String(localized: "Fuel injector issue"), String(localized: "Low compression")],
                symptoms: [String(localized: "Rough idle"), String(localized: "Loss of power"), String(localized: "Increased emissions")]),

        DTCCode(id: "P0304", description: String(localized: "Cylinder 4 Misfire Detected"), severity: .critical,
                possibleCauses: [String(localized: "Faulty spark plug in cylinder 4"), String(localized: "Faulty ignition coil"), String(localized: "Fuel injector issue"), String(localized: "Low compression")],
                symptoms: [String(localized: "Rough idle"), String(localized: "Loss of power"), String(localized: "Increased emissions")]),

        DTCCode(id: "P0305", description: String(localized: "Cylinder 5 Misfire Detected"), severity: .critical,
                possibleCauses: [String(localized: "Faulty spark plug in cylinder 5"), String(localized: "Faulty ignition coil"), String(localized: "Fuel injector issue"), String(localized: "Low compression")],
                symptoms: [String(localized: "Rough idle"), String(localized: "Loss of power"), String(localized: "Increased emissions")]),

        DTCCode(id: "P0306", description: String(localized: "Cylinder 6 Misfire Detected"), severity: .critical,
                possibleCauses: [String(localized: "Faulty spark plug in cylinder 6"), String(localized: "Faulty ignition coil"), String(localized: "Fuel injector issue"), String(localized: "Low compression")],
                symptoms: [String(localized: "Rough idle"), String(localized: "Loss of power"), String(localized: "Increased emissions")]),

        // Catalyst System
        DTCCode(id: "P0420", description: String(localized: "Catalyst System Efficiency Below Threshold (Bank 1)"), severity: .warning,
                possibleCauses: [String(localized: "Failing catalytic converter"), String(localized: "Faulty O2 sensor"), String(localized: "Exhaust leak"), String(localized: "Engine misfire damage")],
                symptoms: [String(localized: "Check Engine Light on"), String(localized: "Reduced fuel economy"), String(localized: "Failed emissions test"), String(localized: "Sulfur smell")]),

        DTCCode(id: "P0430", description: String(localized: "Catalyst System Efficiency Below Threshold (Bank 2)"), severity: .warning,
                possibleCauses: [String(localized: "Failing catalytic converter"), String(localized: "Faulty O2 sensor"), String(localized: "Exhaust leak")],
                symptoms: [String(localized: "Check Engine Light on"), String(localized: "Failed emissions test"), String(localized: "Sulfur smell")]),

        // EVAP System
        DTCCode(id: "P0440", description: String(localized: "Evaporative Emission Control System Malfunction"), severity: .info,
                possibleCauses: [String(localized: "Loose gas cap"), String(localized: "EVAP canister issue"), String(localized: "Faulty purge valve"), String(localized: "Leak in EVAP system")],
                symptoms: [String(localized: "Check Engine Light on"), String(localized: "Fuel odor")]),

        DTCCode(id: "P0442", description: String(localized: "Evaporative Emission System Leak Detected (Small Leak)"), severity: .info,
                possibleCauses: [String(localized: "Loose or damaged gas cap"), String(localized: "Small leak in EVAP hose"), String(localized: "Faulty purge valve")],
                symptoms: [String(localized: "Check Engine Light on"), String(localized: "Slight fuel odor")]),

        DTCCode(id: "P0446", description: String(localized: "Evaporative Emission System Vent Control Circuit"), severity: .info,
                possibleCauses: [String(localized: "Faulty vent valve"), String(localized: "Blockage in vent line"), String(localized: "Wiring issue")],
                symptoms: [String(localized: "Check Engine Light on"), String(localized: "Difficulty refueling")]),

        DTCCode(id: "P0455", description: String(localized: "Evaporative Emission System Leak Detected (Large Leak)"), severity: .warning,
                possibleCauses: [String(localized: "Missing or loose gas cap"), String(localized: "Cracked EVAP hose"), String(localized: "Faulty purge valve")],
                symptoms: [String(localized: "Check Engine Light on"), String(localized: "Strong fuel odor")]),

        // EGR System
        DTCCode(id: "P0401", description: String(localized: "Exhaust Gas Recirculation Flow Insufficient"), severity: .warning,
                possibleCauses: [String(localized: "Clogged EGR passages"), String(localized: "Faulty EGR valve"), String(localized: "Carbon buildup")],
                symptoms: [String(localized: "Engine knock"), String(localized: "Rough idle"), String(localized: "Failed emissions test")]),

        DTCCode(id: "P0402", description: String(localized: "Exhaust Gas Recirculation Flow Excessive"), severity: .warning,
                possibleCauses: [String(localized: "Stuck open EGR valve"), String(localized: "Vacuum leak to EGR"), String(localized: "Faulty DPFE sensor")],
                symptoms: [String(localized: "Rough idle"), String(localized: "Stalling"), String(localized: "Poor acceleration")]),

        // Vehicle Speed and Transmission
        DTCCode(id: "P0500", description: String(localized: "Vehicle Speed Sensor Malfunction"), severity: .warning,
                possibleCauses: [String(localized: "Faulty VSS"), String(localized: "Damaged wiring"), String(localized: "Faulty instrument cluster")],
                symptoms: [String(localized: "Speedometer not working"), String(localized: "Transmission shifting issues"), String(localized: "ABS light on")]),

        DTCCode(id: "P0505", description: String(localized: "Idle Air Control System Malfunction"), severity: .warning,
                possibleCauses: [String(localized: "Faulty IAC valve"), String(localized: "Vacuum leak"), String(localized: "Dirty throttle body"), String(localized: "Wiring issue")],
                symptoms: [String(localized: "Erratic idle"), String(localized: "Stalling"), String(localized: "High idle")]),

        DTCCode(id: "P0700", description: String(localized: "Transmission Control System Malfunction"), severity: .warning,
                possibleCauses: [String(localized: "Transmission issue detected"), String(localized: "Low transmission fluid"), String(localized: "Solenoid failure")],
                symptoms: [String(localized: "Check Engine Light on"), String(localized: "Transmission warning light"), String(localized: "Shifting problems")]),

        DTCCode(id: "P0715", description: String(localized: "Input/Turbine Speed Sensor Circuit Malfunction"), severity: .warning,
                possibleCauses: [String(localized: "Faulty input speed sensor"), String(localized: "Damaged wiring"), String(localized: "Low transmission fluid")],
                symptoms: [String(localized: "Harsh shifting"), String(localized: "Transmission slipping"), String(localized: "No speedometer reading")]),

        // Body Codes
        DTCCode(id: "B0001", description: String(localized: "Driver Frontal Stage 1 Deployment Control"), severity: .critical,
                possibleCauses: [String(localized: "Airbag system malfunction"), String(localized: "Faulty clockspring"), String(localized: "Wiring issue")],
                symptoms: [String(localized: "Airbag warning light on"), String(localized: "Airbag may not deploy")]),

        DTCCode(id: "B0100", description: String(localized: "Electronic Frontal Sensor 1 Performance"), severity: .critical,
                possibleCauses: [String(localized: "Damaged crash sensor"), String(localized: "Wiring issue"), String(localized: "Module failure")],
                symptoms: [String(localized: "Airbag warning light on")]),

        // Chassis Codes
        DTCCode(id: "C0035", description: String(localized: "Left Front Wheel Speed Sensor Circuit"), severity: .warning,
                possibleCauses: [String(localized: "Faulty wheel speed sensor"), String(localized: "Damaged wiring"), String(localized: "Damaged tone ring")],
                symptoms: [String(localized: "ABS light on"), String(localized: "Traction control disabled")]),

        DTCCode(id: "C0040", description: String(localized: "Right Front Wheel Speed Sensor Circuit"), severity: .warning,
                possibleCauses: [String(localized: "Faulty wheel speed sensor"), String(localized: "Damaged wiring"), String(localized: "Damaged tone ring")],
                symptoms: [String(localized: "ABS light on"), String(localized: "Traction control disabled")]),

        DTCCode(id: "C0045", description: String(localized: "Left Rear Wheel Speed Sensor Circuit"), severity: .warning,
                possibleCauses: [String(localized: "Faulty wheel speed sensor"), String(localized: "Damaged wiring"), String(localized: "Damaged tone ring")],
                symptoms: [String(localized: "ABS light on"), String(localized: "Traction control disabled")]),

        DTCCode(id: "C0050", description: String(localized: "Right Rear Wheel Speed Sensor Circuit"), severity: .warning,
                possibleCauses: [String(localized: "Faulty wheel speed sensor"), String(localized: "Damaged wiring"), String(localized: "Damaged tone ring")],
                symptoms: [String(localized: "ABS light on"), String(localized: "Traction control disabled")]),

        // Network Codes
        DTCCode(id: "U0001", description: String(localized: "High Speed CAN Communication Bus"), severity: .warning,
                possibleCauses: [String(localized: "CAN bus wiring issue"), String(localized: "Faulty module"), String(localized: "Short circuit")],
                symptoms: [String(localized: "Multiple warning lights"), String(localized: "Communication errors between modules")]),

        DTCCode(id: "U0100", description: String(localized: "Lost Communication With ECM/PCM"), severity: .critical,
                possibleCauses: [String(localized: "Faulty ECM/PCM"), String(localized: "CAN bus wiring issue"), String(localized: "Power/ground issue")],
                symptoms: [String(localized: "No start condition"), String(localized: "Multiple DTCs"), String(localized: "Limp mode")]),

        DTCCode(id: "U0101", description: String(localized: "Lost Communication With TCM"), severity: .warning,
                possibleCauses: [String(localized: "Faulty TCM"), String(localized: "CAN bus wiring issue"), String(localized: "TCM power issue")],
                symptoms: [String(localized: "Transmission in limp mode"), String(localized: "No shifting")]),

        DTCCode(id: "U0121", description: String(localized: "Lost Communication With Anti-Lock Brake System Module"), severity: .warning,
                possibleCauses: [String(localized: "Faulty ABS module"), String(localized: "CAN bus wiring issue"), String(localized: "ABS fuse blown")],
                symptoms: [String(localized: "ABS light on"), String(localized: "ABS not functional")]),

        DTCCode(id: "U0140", description: String(localized: "Lost Communication With Body Control Module"), severity: .warning,
                possibleCauses: [String(localized: "Faulty BCM"), String(localized: "CAN bus wiring issue"), String(localized: "BCM power issue")],
                symptoms: [String(localized: "Various electrical issues"), String(localized: "Warning lights")]),
    ]
}

// MARK: - JSON Decoding Support

private struct DTCDatabaseWrapper: Codable {
    let version: String
    let codes: [DTCCode]
}
