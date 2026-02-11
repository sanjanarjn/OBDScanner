# CLAUDE.md — OBDScanner

## Project Overview

OBDScanner is a native iOS app (Swift/SwiftUI) for real-time OBD-II vehicle diagnostics over WiFi. It communicates with ELM327-compatible OBD-II adapters via TCP to read live engine parameters and diagnostic trouble codes (DTCs).

## Tech Stack

- **Language:** Swift 5+
- **UI Framework:** SwiftUI
- **Networking:** Network framework (`NWConnection`, TCP)
- **Reactive State:** Combine (`ObservableObject`, `@Published`)
- **Target:** iOS 15.0+
- **IDE:** Xcode 14+
- **Dependencies:** None (no CocoaPods, SPM, or Carthage)

## Project Structure

```
OBDScanner/
├── OBDScannerApp.swift          # @main entry point
├── ContentView.swift            # Root TabView + OBDConnection class
├── OBDParameter.swift           # OBD parameter enum + parsing
├── ParameterCardView.swift      # Dashboard gauge card component
├── ParameterDetailView.swift    # Parameter detail view
├── SettingsView.swift           # Settings tab (demo mode, connection)
├── Managers/
│   ├── DTCManager.swift         # DTC scanning/clearing (Mode 03/04)
│   └── DTCDatabase.swift        # DTC code lookup (singleton, 215 codes)
├── Models/
│   └── DTCCode.swift            # DTC data structures
├── Views/
│   ├── DashboardView.swift      # Real-time parameter grid
│   ├── DiagnosticsView.swift    # DTC scanning UI
│   └── DTCDetailView.swift      # DTC detail view
└── Resources/
    └── dtc_database.json        # DTC database (215 codes)
```

## Architecture

**Pattern:** MVVM with ObservableObject

- **OBDConnection** (`ContentView.swift`) — Central class managing TCP connection, ELM327 initialization, parameter polling, and demo mode simulation. Uses `@StateObject` at the root.
- **DTCManager** (`Managers/DTCManager.swift`) — Handles DTC read (Mode 03), clear (Mode 04), and freeze frame (Mode 02). OBDConnection holds a weak reference to it.
- **DTCDatabase** (`Managers/DTCDatabase.swift`) — Singleton that loads `dtc_database.json` with fallback to built-in codes.

**Data Flow:**
```
UI (SwiftUI Views)
  → OBDConnection (TCP via NWConnection)
    → WiFi OBD-II Adapter (192.168.0.10:35000)
      → Vehicle ECU → Response parsed → @Published properties → UI updates
```

## Build & Run

```bash
# Open in Xcode
open OBDScanner.xcodeproj

# Build and run on simulator or device from Xcode (Cmd+R)
```

No command-line build scripts are configured. Build exclusively through Xcode.

## Testing

No formal test targets exist. Testing is done via:
- **Demo mode** — Toggle in Settings tab; provides simulated OBD data with drifting values
- **Manual testing** — Real WiFi OBD-II adapter (default: `192.168.0.10:35000`)
- **SwiftUI Previews** — Available in view files

## Code Conventions

- **Naming:** PascalCase for types/enums, camelCase for properties/functions
- **State:** `@StateObject` at root, `@ObservedObject` in child views, `@Published` for observable properties
- **Colors:** Global constants `accentGreen`, `cardBackground` for dark theme
- **Network calls:** Dispatch to global queue, UI updates on `DispatchQueue.main`
- **Memory:** Weak self captures in closures to prevent retain cycles
- **OBD parsing:** Supports both space-separated (`"41 0C 1A F8"`) and compact (`"410C1AF8"`) hex formats
- **Flags:** `isDTCOperation`, `isWaitingForResponse`, `isActive` for connection state serialization
- **Helper views:** Small reusable structs like `ConnectionStatusBanner`, `ScanButton`, `DTCRowView` defined alongside their parent views

## Key Technical Details

- **ELM327 init sequence:** ATZ → ATE0 → ATL0 → ATH1 → ATSP0
- **Polling interval:** 0.3s between sequential parameter requests
- **Demo mode interval:** 1.5s update cycle with random drift
- **Network timeout:** 8–10 seconds per request
- **DTC format:** 2-byte hex decoded to standard codes (e.g., `0300` → `P0300`)
- **Supported PIDs:** 010C (RPM), 010D (Speed), 0105 (Coolant Temp), 0104 (Engine Load), 0111 (Throttle), 012F (Fuel Level), 010F (Intake Air Temp), 0110 (MAF), 010E (Timing Advance)

## Active Development

- **Current branch:** `feature/dtc-diagnostics`
- **Roadmap:** See `OBD_Scanner_Feature_Roadmap.md` for planned features (BLE support, custom dashboard, data logging, HUD mode, performance metrics)

## Common Tasks

- **Add a new OBD parameter:** Add a case to `OBDParameterType` enum in `OBDParameter.swift`, implement `parseValue()`, add to the polling list in `OBDConnection`
- **Add DTC codes:** Edit `Resources/dtc_database.json`
- **Modify connection settings:** Default host/port in `OBDConnection` class (`ContentView.swift`)
