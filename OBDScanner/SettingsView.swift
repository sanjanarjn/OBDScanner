import SwiftUI

struct SettingsView: View {
    @ObservedObject var obd: OBDConnection
    @ObservedObject var dtcManager: DTCManager

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                List {
                    // Demo Mode Section
                    Section {
                        Toggle("Demo Mode", isOn: $obd.isDemoMode)
                            .tint(accentGreen)
                            .foregroundColor(.white)
                            .listRowBackground(cardBackground)
                    } footer: {
                        Text("Shows realistic simulated OBD data and sample trouble codes. No vehicle connection required.")
                            .foregroundColor(Color(white: 0.5))
                    }

                    // Connection Section
                    Section {
                        HStack {
                            Text("Connection Status")
                                .foregroundColor(.white)
                            Spacer()
                            Text(obd.isDemoMode ? "Demo" : (obd.isConnected ? "Connected" : "Disconnected"))
                                .foregroundColor(obd.isConnected || obd.isDemoMode ? accentGreen : Color(white: 0.5))
                        }
                        .listRowBackground(cardBackground)

                        if !obd.isDemoMode {
                            HStack {
                                Text("Adapter IP")
                                    .foregroundColor(.white)
                                Spacer()
                                Text("192.168.0.10:35000")
                                    .foregroundColor(Color(white: 0.5))
                            }
                            .listRowBackground(cardBackground)
                        }
                    } header: {
                        Text("Connection")
                    }

                    // Diagnostics Section
                    Section {
                        HStack {
                            Text("Active Trouble Codes")
                                .foregroundColor(.white)
                            Spacer()
                            if dtcManager.activeDTCs.count > 0 {
                                Text("\(dtcManager.activeDTCs.count)")
                                    .foregroundColor(.red)
                                    .fontWeight(.semibold)
                            } else {
                                Text("None")
                                    .foregroundColor(Color(white: 0.5))
                            }
                        }
                        .listRowBackground(cardBackground)

                        if let lastScan = dtcManager.lastScanDate {
                            HStack {
                                Text("Last Scan")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(lastScan.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundColor(Color(white: 0.5))
                            }
                            .listRowBackground(cardBackground)
                        }
                    } header: {
                        Text("Diagnostics")
                    }

                    // About Section
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(Color(white: 0.5))
                        }
                        .listRowBackground(cardBackground)

                        HStack {
                            Text("Supported Protocols")
                                .foregroundColor(.white)
                            Spacer()
                            Text("OBD-II (ISO 9141, CAN)")
                                .foregroundColor(Color(white: 0.5))
                                .font(.caption)
                        }
                        .listRowBackground(cardBackground)
                    } header: {
                        Text("About")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
        .onChange(of: obd.isDemoMode) { _, newValue in
            if newValue {
                obd.startDemo()
            } else {
                obd.stopDemo()
            }
        }
    }
}
