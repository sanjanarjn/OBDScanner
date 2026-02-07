import SwiftUI

struct ParameterCardView: View {
    let parameter: OBDParameterData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Title
            Text(parameter.type.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            // Icon + Value row
            HStack(alignment: .bottom) {
                Image(systemName: parameter.type.iconName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(accentGreen)

                Spacer()

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(parameter.value == "N/A" ? "--" : parameter.value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if parameter.value != "N/A" {
                        Text(parameter.type.unit)
                            .font(.caption)
                            .foregroundColor(Color(white: 0.5))
                    }
                }
            }

            // Detail link
            HStack(spacing: 4) {
                Text("Details")
                    .font(.caption)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(accentGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .frame(minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentGreen.opacity(0.12), lineWidth: 1)
                )
        )
    }
}
