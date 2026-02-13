import SwiftUI

struct DashboardView: View {
    @ObservedObject var obd: OBDConnection

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Connection status banner
                        ConnectionStatusBanner(
                            isConnected: obd.isConnected,
                            isDemoMode: obd.isDemoMode,
                            connectionType: obd.connectionType,
                            peripheralName: obd.connectedPeripheralName
                        )

                        // Connection button (hidden when in demo mode)
                        if obd.isDemoMode {
                            // Show demo mode indicator instead of connect/disconnect
                            HStack(spacing: 10) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)
                                Text("Demo Mode Active")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(accentGreen.opacity(0.7))
                            .cornerRadius(14)
                            .padding(.horizontal)
                        } else if !obd.isConnected {
                            Button(action: {
                                obd.connect()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "bolt.circle.fill")
                                        .font(.title3)
                                    Text("Connect to OBD-II")
                                }
                                .font(.headline)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(accentGreen)
                                .cornerRadius(14)
                                .shadow(color: accentGreen.opacity(0.3), radius: 8, y: 4)
                            }
                            .padding(.horizontal)
                        } else {
                            Button(action: {
                                obd.disconnect()
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                    Text("Disconnect")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color(white: 0.20))
                                .cornerRadius(14)
                            }
                            .padding(.horizontal)
                        }

                        // Grid of parameters
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 14),
                            GridItem(.flexible(), spacing: 14)
                        ], spacing: 14) {
                            ForEach(obd.parameters) { parameter in
                                NavigationLink(destination: ParameterDetailView(parameter: parameter)) {
                                    ParameterCardView(parameter: parameter)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Dashboard")
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Connection Status Banner

struct ConnectionStatusBanner: View {
    let isConnected: Bool
    var isDemoMode: Bool = false
    var connectionType: ConnectionType = .wifi
    var peripheralName: String? = nil

    var body: some View {
        HStack {
            Circle()
                .fill(isConnected ? accentGreen : Color.gray)
                .frame(width: 10, height: 10)
                .shadow(color: isConnected ? accentGreen.opacity(0.6) : .clear, radius: 4)

            Text(isDemoMode ? "Demo Mode" : (isConnected ? "Connected" : "Not Connected"))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Spacer()

            if isDemoMode {
                HStack(spacing: 4) {
                    Image(systemName: "play.circle")
                        .foregroundColor(accentGreen)
                    Text("Simulated")
                }
                .font(.caption)
                .foregroundColor(Color(white: 0.5))
            } else if isConnected {
                HStack(spacing: 4) {
                    if connectionType == .ble {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(accentGreen)
                        Text(peripheralName ?? "BLE")
                    } else {
                        Image(systemName: "wifi")
                            .foregroundColor(accentGreen)
                        Text("192.168.0.10")
                    }
                }
                .font(.caption)
                .foregroundColor(Color(white: 0.5))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentGreen.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}
