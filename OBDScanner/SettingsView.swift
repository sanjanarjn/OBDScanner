import SwiftUI

struct SettingsView: View {
    @ObservedObject var obd: OBDConnection

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            List {
                Section {
                    Toggle("Demo Mode", isOn: $obd.isDemoMode)
                        .tint(accentGreen)
                        .foregroundColor(.white)
                        .listRowBackground(cardBackground)
                } footer: {
                    Text("Shows realistic simulated OBD data that updates in real-time. No vehicle connection required.")
                        .foregroundColor(Color(white: 0.5))
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .onChange(of: obd.isDemoMode) { newValue in
            if newValue {
                obd.startDemo()
            } else {
                obd.stopDemo()
            }
        }
    }
}
