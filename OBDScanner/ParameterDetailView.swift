import SwiftUI

struct ParameterDetailView: View {
    let parameter: OBDParameterData

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header with icon and current value
                    VStack(spacing: 16) {
                        Image(systemName: parameter.type.iconName)
                            .font(.system(size: 56, weight: .medium))
                            .foregroundColor(accentGreen)
                            .shadow(color: accentGreen.opacity(0.4), radius: 10)

                        Text(parameter.type.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(verbatim: parameter.value == "N/A" ? "--" : parameter.value)
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            if parameter.value != "N/A" {
                                Text(verbatim: parameter.type.unit)
                                    .font(.title3)
                                    .foregroundColor(Color(white: 0.5))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(accentGreen.opacity(0.15), lineWidth: 1)
                            )
                    )

                    // Description section
                    SectionView(title: "What is this?", icon: "info.circle") {
                        Text(parameter.type.description)
                            .font(.body)
                            .foregroundColor(Color(white: 0.75))
                    }

                    // Normal range section
                    SectionView(title: "Normal Range", icon: "chart.line.uptrend.xyaxis") {
                        Text(parameter.type.normalRange)
                            .font(.body)
                            .foregroundColor(Color(white: 0.75))
                    }

                    // Tips section
                    SectionView(title: "Tips & Advice", icon: "lightbulb") {
                        Text(parameter.type.tips)
                            .font(.body)
                            .foregroundColor(Color(white: 0.75))
                    }

                    // Last updated
                    if parameter.value != "N/A" {
                        Text("Last updated: \(parameter.lastUpdated.formatted(date: .omitted, time: .standard))")
                            .font(.caption)
                            .foregroundColor(Color(white: 0.4))
                            .padding(.top, 8)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}

struct SectionView<Content: View>: View {
    let title: LocalizedStringKey
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(accentGreen)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
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
