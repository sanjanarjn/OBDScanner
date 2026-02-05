import SwiftUI

struct ParameterDetailView: View {
    let parameter: OBDParameterData

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with icon and current value
                VStack(spacing: 16) {
                    Image(systemName: parameter.type.iconName)
                        .font(.system(size: 64))
                        .foregroundColor(iconColor)

                    Text(parameter.type.title)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(parameter.displayValue)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(parameter.value == "N/A" ? .gray : .primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                )

                // Description section
                SectionView(title: "What is this?", icon: "info.circle") {
                    Text(parameter.type.description)
                        .font(.body)
                        .foregroundColor(.primary)
                }

                // Normal range section
                SectionView(title: "Normal Range", icon: "chart.line.uptrend.xyaxis") {
                    Text(parameter.type.normalRange)
                        .font(.body)
                        .foregroundColor(.primary)
                }

                // Tips section
                SectionView(title: "Tips & Advice", icon: "lightbulb") {
                    Text(parameter.type.tips)
                        .font(.body)
                        .foregroundColor(.primary)
                }

                // Last updated
                if parameter.value != "N/A" {
                    Text("Last updated: \(parameter.lastUpdated.formatted(date: .omitted, time: .standard))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var iconColor: Color {
        if parameter.value == "N/A" {
            return .gray
        }

        switch parameter.type {
        case .rpm: return .blue
        case .speed: return .green
        case .coolantTemp: return .orange
        case .engineLoad: return .purple
        case .throttlePosition: return .indigo
        case .fuelLevel: return .yellow
        case .intakeAirTemp: return .cyan
        case .maf: return .mint
        case .timing: return .pink
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
