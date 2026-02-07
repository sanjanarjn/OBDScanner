# OBD Scanner App — Feature Roadmap

## Reference App
**Car Scanner ELM OBD2** — https://apps.apple.com/us/app/car-scanner-elm-obd2/id1259933623

---

## Current State of Our App
- Real-time monitoring of 9 OBD-II parameters via WiFi (ELM327)
- Dark-themed UI with parameter cards in a 2-column grid
- Parameter detail views with descriptions, normal ranges, and tips
- Demo/simulation mode with realistic drifting values
- Settings screen with demo toggle

---

## Feature Comparison

| Feature | Car Scanner ELM OBD2 | Our OBD Scanner |
|---|---|---|
| Real-time sensor monitoring | 9+ parameters on one screen | 9 parameters in grid |
| DTC fault code reading/reset | Yes, with huge DTC database | No |
| Custom dashboard/gauges | Configurable gauges, dials, charts | Fixed card layout |
| HUD mode | Yes (windshield projection) | No |
| Performance testing | 0-60, 0-100 acceleration | No |
| Trip computer | Yes | No |
| Fuel consumption tracking | Yes | No |
| Data recording & playback | Yes, with CSV export | No |
| Map/GPS tracking | Position tracking during recording | No |
| Emission readiness test | Yes | No |
| Freeze frame data | Yes | No |
| Mode 06 ECU tests | Yes | No |
| Custom PIDs | Yes (manufacturer-hidden data) | No |
| Multi-vehicle profiles | Yes | No |
| Manufacturer-specific support | Toyota, BMW, VW/Audi, GM, etc. | Generic OBD-II only |
| WiFi + BLE adapters | Both | WiFi only |
| Dark theme UI | Yes | Yes |
| Demo/simulation mode | Unknown | Yes |
| Parameter detail info & tips | Limited | Yes, per parameter |

---

## Feature Roadmap (Prioritized Phases)

### Phase 1 — DTC Fault Codes (High Impact)
The #1 reason people download OBD apps. Without this, the app is a dashboard only.

- **Read DTCs**: Send Mode 03 command, parse response into P/B/C/U codes
- **Clear DTCs**: Send Mode 04 command with user confirmation dialog
- **DTC Database**: Bundle a local JSON/plist of ~15,000 OBD-II code descriptions
- **Freeze Frame**: Send Mode 02 to capture sensor snapshot when fault occurred
- **New screens**: DTCListView (list of active codes with descriptions), DTCDetailView (per-code info + freeze frame)
- **UI**: Add a "Diagnostics" tab or section on the main screen showing active code count with a warning badge

### Phase 2 — Bluetooth LE Support
Most modern ELM327 adapters use BLE. WiFi-only limits device compatibility.

- Add CoreBluetooth framework integration
- Scan for BLE ELM327 devices (common service UUIDs: FFF0, FFE0)
- Abstract connection layer: protocol OBDTransport with WiFiTransport and BLETransport conformances
- Connection picker UI in settings: WiFi vs Bluetooth, with BLE device scanner
- Handle BLE-specific chunked responses (20-byte MTU)

### Phase 3 — Custom Dashboard
Let users choose which parameters to see and how they're displayed.

- **Gauge types**: Digital readout (current), circular dial gauge, linear bar gauge
- **Dashboard editor**: Long-press to enter edit mode, drag to reorder, tap to change gauge type
- **Favorites**: Toggle parameters on/off from the dashboard
- **Persistence**: Save layout to UserDefaults or a local JSON file
- Modify ParameterCardView to support multiple visual modes

### Phase 4 — Data Logging & Export
Record sessions for later analysis — essential for mechanics and enthusiasts.

- **Recording engine**: Capture timestamped parameter snapshots during a session
- **Storage**: Core Data or JSON files per session, with metadata (date, duration, vehicle)
- **Playback screen**: Scrollable time-series charts per parameter (use Swift Charts)
- **CSV export**: Share sheet with CSV file of recorded data
- **UI**: Record button on main screen, session list in a "History" tab

### Phase 5 — HUD Mode
Display speed/RPM mirrored on windshield. Popular for night driving.

- New full-screen HUDView showing key values (speed, RPM) in large mirrored text
- Use CGAffineTransform(scaleX: -1, y: 1) for horizontal mirror
- Minimal UI: black background, bright green/white text, auto screen-on
- Entry point: button on main screen or in settings

### Phase 6 — Performance Metrics
0-60 mph, quarter mile, horsepower estimation.

- **Acceleration timer**: Detect speed crossing thresholds (0→60, 0→100 km/h)
- **Results screen**: Show time, top speed, peak RPM during run
- **History**: Store past runs for comparison
- Requires faster polling rate (~100ms) for accuracy during performance runs

### Phase 7 — Multi-Vehicle Profiles
Save per-vehicle settings and history.

- Vehicle model: name, year, make (user-entered)
- Per-vehicle: connection settings, dashboard layout, DTC history, data logs
- Profile switcher in settings or on launch
- Store via Core Data or JSON files per profile

### Phase 8 — Emission Readiness
Required for smog checks in many states.

- Send Mode 01 PID 01 to read monitor status
- Parse readiness flags for each emission monitor (catalyst, O2 sensor, EGR, etc.)
- Display pass/fail/incomplete status per monitor
- Simple checklist UI: EmissionReadinessView

### Phase 9 — Manufacturer-Specific Profiles
Enhanced data for specific car brands beyond standard OBD-II.

- Extended PID databases per manufacturer (Toyota, BMW, VW/Audi, GM, etc.)
- Manufacturer-specific DTC codes
- This is a long-tail effort — start with 1-2 popular brands and expand

---

## Summary Table

| Phase | Feature | Complexity | User Impact |
|-------|---------|-----------|-------------|
| 1 | DTC Fault Codes | Medium | Very High |
| 2 | Bluetooth LE | Medium | High |
| 3 | Custom Dashboard | Medium | High |
| 4 | Data Logging & Export | Medium-High | High |
| 5 | HUD Mode | Low | Medium |
| 6 | Performance Metrics | Medium | Medium |
| 7 | Multi-Vehicle Profiles | Medium | Medium |
| 8 | Emission Readiness | Low-Medium | Medium |
| 9 | Manufacturer Profiles | High (ongoing) | Medium |
