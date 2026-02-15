import SwiftUI

struct DTCDetailView: View {
    let dtc: ActiveDTC

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    DTCHeaderCard(dtc: dtc)

                    // Description section
                    SectionView(title: "Description", icon: "doc.text") {
                        Text(dtc.code.description)
                            .font(.body)
                            .foregroundColor(Color(white: 0.75))
                    }

                    // Possible Causes section
                    SectionView(title: "Possible Causes", icon: "wrench.and.screwdriver") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(dtc.code.possibleCauses, id: \.self) { cause in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(accentGreen)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)

                                    Text(cause)
                                        .font(.body)
                                        .foregroundColor(Color(white: 0.75))
                                }
                            }
                        }
                    }

                    // Symptoms section
                    SectionView(title: "Symptoms", icon: "exclamationmark.circle") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(dtc.code.symptoms, id: \.self) { symptom in
                                HStack(alignment: .top, spacing: 10) {
                                    Circle()
                                        .fill(dtc.code.severity.color)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 6)

                                    Text(symptom)
                                        .font(.body)
                                        .foregroundColor(Color(white: 0.75))
                                }
                            }
                        }
                    }

                    // Freeze Frame section (if available)
                    if let freezeFrame = dtc.freezeFrame, freezeFrame.hasData {
                        FreezeFrameSection(data: freezeFrame)
                    }

                    // Detection info
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(Color(white: 0.4))

                            Text("Detected: \(dtc.detectedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption)
                                .foregroundColor(Color(white: 0.4))

                            Spacer()
                        }

                        HStack {
                            Image(systemName: "tag")
                                .font(.caption)
                                .foregroundColor(Color(white: 0.4))

                            Text("Code Type: \(dtc.code.isGeneric ? "Generic (SAE)" : "Manufacturer Specific")")
                                .font(.caption)
                                .foregroundColor(Color(white: 0.4))

                            Spacer()
                        }
                    }
                    .padding(.top, 8)
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(dtc.code.id)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Header Card

struct DTCHeaderCard: View {
    let dtc: ActiveDTC

    var body: some View {
        VStack(spacing: 16) {
            // Severity Icon
            Image(systemName: dtc.code.severity.iconName)
                .font(.system(size: 56, weight: .medium))
                .foregroundColor(dtc.code.severity.color)
                .shadow(color: dtc.code.severity.color.opacity(0.4), radius: 10)

            // Code
            Text(verbatim: dtc.code.id)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            // Category and Severity badges
            HStack(spacing: 12) {
                // Category badge
                HStack(spacing: 4) {
                    Image(systemName: categoryIcon)
                        .font(.caption)
                    Text(dtc.code.category.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(white: 0.25))
                )

                // Severity badge
                HStack(spacing: 4) {
                    Image(systemName: dtc.code.severity.iconName)
                        .font(.caption)
                    Text(dtc.code.severity.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(dtc.code.severity.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(dtc.code.severity.color.opacity(0.2))
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(dtc.code.severity.color.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private var categoryIcon: String {
        switch dtc.code.category {
        case .powertrain: return "engine.combustion"
        case .body: return "car.side"
        case .chassis: return "car.circle"
        case .network: return "network"
        }
    }
}

// MARK: - Freeze Frame Section

struct FreezeFrameSection: View {
    let data: FreezeFrameData

    var body: some View {
        SectionView(title: "Freeze Frame Data", icon: "camera.viewfinder") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Sensor snapshot captured when fault occurred:")
                    .font(.caption)
                    .foregroundColor(Color(white: 0.5))

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    if let rpm = data.rpm {
                        FreezeFrameItem(label: "RPM", value: "\(rpm)", unit: "RPM")
                    }
                    if let speed = data.speed {
                        FreezeFrameItem(label: "Speed", value: "\(speed)", unit: "km/h")
                    }
                    if let coolant = data.coolantTemp {
                        FreezeFrameItem(label: "Coolant", value: "\(coolant)", unit: "°C")
                    }
                    if let load = data.engineLoad {
                        FreezeFrameItem(label: "Load", value: "\(load)", unit: "%")
                    }
                    if let throttle = data.throttlePosition {
                        FreezeFrameItem(label: "Throttle", value: "\(throttle)", unit: "%")
                    }
                    if let intake = data.intakeAirTemp {
                        FreezeFrameItem(label: "Intake Air", value: "\(intake)", unit: "°C")
                    }
                    if let maf = data.maf {
                        FreezeFrameItem(label: "MAF", value: String(format: "%.1f", maf), unit: "g/s")
                    }
                }

                // Timestamp
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text("Captured: \(data.capturedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                }
                .foregroundColor(Color(white: 0.4))
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Freeze Frame Item

struct FreezeFrameItem: View {
    let label: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(Color(white: 0.5))

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(verbatim: value)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(verbatim: unit)
                    .font(.caption)
                    .foregroundColor(Color(white: 0.5))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.12))
        )
    }
}
