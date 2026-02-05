import SwiftUI

struct ParameterCardView: View {
    let parameter: OBDParameterData

    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: parameter.type.iconName)
                .font(.system(size: 34, weight: .medium))
                .foregroundColor(cardColor)
                .shadow(color: cardColor.opacity(0.5), radius: 6)
                .frame(height: 42)

            // Title
            Text(parameter.type.title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // Value
            Text(parameter.value == "N/A" ? "N/A" : parameter.value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(parameter.value == "N/A" ? .gray : .white)

            // Unit
            if parameter.value != "N/A" {
                Text(parameter.type.unit)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var cardColor: Color {
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
