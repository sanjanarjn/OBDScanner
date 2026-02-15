import SwiftUI

struct DiagnosticsView: View {
    @ObservedObject var obd: OBDConnection
    @ObservedObject var dtcManager: DTCManager
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Status Card
                        DiagnosticsStatusCard(
                            isConnected: obd.isConnected || obd.isDemoMode,
                            lastScan: dtcManager.lastScanDate,
                            codeCount: dtcManager.activeDTCs.count
                        )

                        // Scan Button
                        ScanButton(
                            isScanning: dtcManager.isScanning,
                            isEnabled: obd.isConnected || obd.isDemoMode
                        ) {
                            if obd.isDemoMode {
                                dtcManager.scanForDTCsDemo()
                            } else {
                                obd.scanForDTCs()
                            }
                        }

                        // Error message if any
                        if let error = dtcManager.scanError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.orange.opacity(0.15))
                            )
                            .padding(.horizontal)
                        }

                        // DTC List or Empty State
                        if dtcManager.activeDTCs.isEmpty {
                            EmptyDTCView(hasScanned: dtcManager.lastScanDate != nil)
                        } else {
                            // DTC List
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Active Trouble Codes")
                                        .font(.headline)
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text("\(dtcManager.activeDTCs.count) codes", comment: "Pluralized code count label")
                                        .font(.subheadline)
                                        .foregroundColor(Color(white: 0.5))
                                }
                                .padding(.horizontal)

                                ForEach(dtcManager.activeDTCs) { dtc in
                                    NavigationLink(destination: DTCDetailView(dtc: dtc)) {
                                        DTCRowView(dtc: dtc)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal)
                            }

                            // Clear Codes Button
                            ClearCodesButton(isClearing: dtcManager.isClearing) {
                                showClearConfirmation = true
                            }
                            .padding(.top, 8)
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle("Diagnostics")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert("Clear Trouble Codes?", isPresented: $showClearConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    if obd.isDemoMode {
                        dtcManager.clearDTCsDemo()
                    } else {
                        obd.clearDTCs()
                    }
                }
            } message: {
                Text("This will clear all stored trouble codes and turn off the Check Engine light. The codes may return if the underlying issue is not fixed.")
            }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Status Card

struct DiagnosticsStatusCard: View {
    let isConnected: Bool
    let lastScan: Date?
    let codeCount: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("System Status")
                        .font(.subheadline)
                        .foregroundColor(Color(white: 0.5))

                    HStack(spacing: 8) {
                        Circle()
                            .fill(isConnected ? accentGreen : Color.gray)
                            .frame(width: 8, height: 8)

                        Text(isConnected ? "Ready to Scan" : "Not Connected")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }

                Spacer()

                // Code count badge
                if codeCount > 0 {
                    VStack(spacing: 2) {
                        Text("\(codeCount)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.red)

                        Text("Active")
                            .font(.caption2)
                            .foregroundColor(Color(white: 0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.15))
                    )
                }
            }

            if let lastScan = lastScan {
                Divider()
                    .background(Color(white: 0.2))

                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.5))

                    Text("Last scanned: \(lastScan.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(Color(white: 0.5))

                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentGreen.opacity(0.12), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - Scan Button

struct ScanButton: View {
    let isScanning: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if isScanning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.title2)
                }

                Text(isScanning ? "Scanning..." : "Scan for Trouble Codes")
                    .font(.headline)
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isEnabled ? accentGreen : Color.gray)
            )
            .shadow(color: isEnabled ? accentGreen.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .disabled(!isEnabled || isScanning)
        .padding(.horizontal)
    }
}

// MARK: - Empty State

struct EmptyDTCView: View {
    let hasScanned: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: hasScanned ? "checkmark.circle.fill" : "car.circle")
                .font(.system(size: 48))
                .foregroundColor(hasScanned ? accentGreen : Color(white: 0.4))

            Text(hasScanned ? "No Trouble Codes Found" : "Ready to Scan")
                .font(.headline)
                .foregroundColor(.white)

            Text(hasScanned
                 ? "Your vehicle's computer reported no active diagnostic trouble codes."
                 : "Connect to your OBD-II adapter and scan to check for trouble codes.")
                .font(.subheadline)
                .foregroundColor(Color(white: 0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentGreen.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}

// MARK: - DTC Row

struct DTCRowView: View {
    let dtc: ActiveDTC

    var body: some View {
        HStack(spacing: 14) {
            // Severity indicator
            Image(systemName: dtc.code.severity.iconName)
                .font(.title2)
                .foregroundColor(dtc.code.severity.color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(verbatim: dtc.code.id)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(accentGreen)

                    Text(dtc.code.category.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(Color(white: 0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color(white: 0.2))
                        )
                }

                Text(dtc.code.description)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(Color(white: 0.4))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(dtc.code.severity.color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Clear Codes Button

struct ClearCodesButton: View {
    let isClearing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isClearing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "trash.circle.fill")
                        .font(.title3)
                }

                Text(isClearing ? "Clearing..." : "Clear All Codes")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(0.8))
            )
        }
        .disabled(isClearing)
        .padding(.horizontal)
    }
}
