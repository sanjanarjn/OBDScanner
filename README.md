# OBDScanner

An iOS app built with SwiftUI that connects to an OBD-II adapter over WiFi to read and display real-time vehicle diagnostics.

## Features

- **Real-time monitoring** of 9 OBD-II parameters with automatic polling every 2 seconds
- **Grid dashboard** with color-coded parameter cards
- **Detail views** for each parameter with descriptions, normal ranges, and driving tips
- **ELM327 compatible** — connects to WiFi OBD-II adapters (e.g., iCar Pro)

## Supported Parameters

| Parameter | PID | Unit |
|---|---|---|
| Engine RPM | 010C | RPM |
| Vehicle Speed | 010D | km/h |
| Coolant Temperature | 0105 | °C |
| Engine Load | 0104 | % |
| Throttle Position | 0111 | % |
| Fuel Level | 012F | % |
| Intake Air Temperature | 010F | °C |
| Mass Air Flow | 0110 | g/s |
| Timing Advance | 010E | ° |

## Requirements

- iOS 15.0+
- Xcode 14+
- A WiFi OBD-II adapter (default: 192.168.0.10:35000)

## Getting Started

1. Clone the repository
   ```bash
   git clone https://github.com/sanjanarjn/OBDScanner.git
   ```
2. Open `OBDScanner.xcodeproj` in Xcode
3. Build and run on your device
4. Connect your phone to the OBD-II adapter's WiFi network
5. Tap **Connect to OBD-II** in the app

## How It Works

1. The app establishes a TCP connection to the WiFi OBD-II adapter
2. Sends ELM327 initialization commands (reset, echo off, auto protocol, etc.)
3. Polls each parameter sequentially, cycling through all 9 PIDs
4. Parses hex responses using standard OBD-II formulas
5. Updates the UI in real-time with decoded values

## Project Structure

```
OBDScanner/
├── OBDScannerApp.swift        # App entry point
├── ContentView.swift          # Main dashboard and OBD connection logic
├── OBDParameter.swift         # Parameter types, PID definitions, and parsing
├── ParameterCardView.swift    # Card UI for the dashboard grid
└── ParameterDetailView.swift  # Detail view with descriptions and tips
```
