import SwiftUI
import CoreBluetooth

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

                    // Connection Type Section
                    if !obd.isDemoMode {
                        Section {
                            Picker("Connection Type", selection: $obd.connectionType) {
                                ForEach(ConnectionType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                            .listRowBackground(cardBackground)
                        } header: {
                            Text("Connection Type")
                        } footer: {
                            Text(obd.connectionType == .ble
                                 ? "Connect to a Bluetooth Low Energy OBD-II adapter (e.g. Veepeak BLE)."
                                 : "Connect to a WiFi OBD-II adapter via TCP.")
                                .foregroundColor(Color(white: 0.5))
                        }
                    }

                    // BLE Section (shown only when BLE selected and not in demo mode)
                    if obd.connectionType == .ble && !obd.isDemoMode {
                        Section {
                            // Bluetooth state
                            HStack {
                                Text("Bluetooth")
                                    .foregroundColor(.white)
                                Spacer()
                                bluetoothStateView
                            }
                            .listRowBackground(cardBackground)

                            if obd.bleTransport.bluetoothState == .poweredOn {
                                // Scan button
                                Button(action: {
                                    if obd.bleTransport.isScanning {
                                        obd.bleTransport.stopScanning()
                                    } else {
                                        obd.bleTransport.startScanning()
                                    }
                                }) {
                                    HStack {
                                        if obd.bleTransport.isScanning {
                                            ProgressView()
                                                .tint(.white)
                                                .scaleEffect(0.8)
                                            Text("Scanning...")
                                                .foregroundColor(.white)
                                        } else {
                                            Image(systemName: "antenna.radiowaves.left.and.right")
                                                .foregroundColor(accentGreen)
                                            Text("Scan for Devices")
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .listRowBackground(cardBackground)

                                // Discovered peripherals
                                ForEach(obd.bleTransport.discoveredPeripherals, id: \.identifier) { peripheral in
                                    Button(action: {
                                        obd.bleTransport.targetPeripheral = peripheral
                                    }) {
                                        HStack {
                                            Image(systemName: "antenna.radiowaves.left.and.right")
                                                .foregroundColor(accentGreen)
                                            Text(peripheral.name ?? "Unknown Device")
                                                .foregroundColor(.white)
                                            Spacer()
                                            if obd.bleTransport.targetPeripheral?.identifier == peripheral.identifier {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(accentGreen)
                                            }
                                        }
                                    }
                                    .listRowBackground(cardBackground)
                                }
                            } else if obd.bleTransport.bluetoothState == .unsupported {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .foregroundColor(.yellow)
                                    Text("Not available on Simulator")
                                        .foregroundColor(Color(white: 0.5))
                                }
                                .listRowBackground(cardBackground)
                            }
                        } header: {
                            Text("Bluetooth Devices")
                        } footer: {
                            Text("Connect from this app only — do not pair in iOS Bluetooth settings.")
                                .foregroundColor(Color(white: 0.5))
                        }
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

                        if !obd.isDemoMode && obd.connectionType == .wifi {
                            HStack {
                                Text("Adapter IP")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(verbatim: "192.168.0.10:35000")
                                    .foregroundColor(Color(white: 0.5))
                            }
                            .listRowBackground(cardBackground)
                        }

                        if !obd.isDemoMode && obd.connectionType == .ble {
                            HStack {
                                Text("Selected Device")
                                    .foregroundColor(.white)
                                Spacer()
                                Text(obd.bleTransport.targetPeripheral?.name ?? "None")
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
                            Text(verbatim: "1.0.0")
                                .foregroundColor(Color(white: 0.5))
                        }
                        .listRowBackground(cardBackground)

                        HStack {
                            Text("Supported Protocols")
                                .foregroundColor(.white)
                            Spacer()
                            Text(verbatim: "OBD-II (ISO 9141, CAN)")
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
        .onChange(of: obd.connectionType) { _, _ in
            // Disconnect when switching connection types
            if obd.isConnected && !obd.isDemoMode {
                obd.disconnect()
            }
        }
    }

    @ViewBuilder
    private var bluetoothStateView: some View {
        switch obd.bleTransport.bluetoothState {
        case .poweredOn:
            HStack(spacing: 4) {
                Circle().fill(accentGreen).frame(width: 8, height: 8)
                Text("Ready")
                    .foregroundColor(accentGreen)
            }
            .font(.caption)
        case .poweredOff:
            HStack(spacing: 4) {
                Circle().fill(Color.red).frame(width: 8, height: 8)
                Text("Off")
                    .foregroundColor(.red)
            }
            .font(.caption)
        case .unauthorized:
            Text("Unauthorized")
                .foregroundColor(.orange)
                .font(.caption)
        case .unsupported:
            Text("Unsupported")
                .foregroundColor(Color(white: 0.5))
                .font(.caption)
        default:
            Text(verbatim: "...")
                .foregroundColor(Color(white: 0.5))
                .font(.caption)
        }
    }
}
