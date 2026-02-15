import Foundation
import CoreBluetooth

class BLETransport: NSObject, ObservableObject, OBDTransport {
    weak var delegate: OBDTransportDelegate?
    private(set) var state: TransportState = .disconnected

    // BLE UUIDs for ELM327 BLE adapters (Veepeak, etc.)
    private let serviceUUID = CBUUID(string: "FFF0")
    private let notifyCharUUID = CBUUID(string: "FFF1")
    private let writeCharUUID = CBUUID(string: "FFF2")

    // CoreBluetooth
    private var centralManager: CBCentralManager?
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristic: CBCharacteristic?

    // Response buffering — BLE MTU is typically 20 bytes, responses arrive fragmented
    private var responseBuffer = ""

    // Published properties for scanning UI
    @Published var isScanning = false
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var bluetoothState: CBManagerState = .unknown

    // User-selected peripheral to connect to
    var targetPeripheral: CBPeripheral?

    // Retain discovered peripherals strongly (CBCentralManager doesn't retain them)
    private var retainedPeripherals: [CBPeripheral] = []

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // MARK: - OBDTransport

    func connect() {
        guard let peripheral = targetPeripheral else {
            let msg = String(localized: "No BLE device selected")
            state = .failed(msg)
            delegate?.transport(self, didChangeState: .failed(msg))
            return
        }

        guard centralManager?.state == .poweredOn else {
            let msg = String(localized: "Bluetooth not available")
            state = .failed(msg)
            delegate?.transport(self, didChangeState: .failed(msg))
            return
        }

        stopScanning()
        state = .connecting
        delegate?.transport(self, didChangeState: .connecting)
        centralManager?.connect(peripheral, options: nil)
        connectedPeripheral = peripheral
    }

    func disconnect() {
        if let peripheral = connectedPeripheral {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        cleanup()
        state = .disconnected
        delegate?.transport(self, didChangeState: .disconnected)
    }

    func send(_ command: String) {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic,
              state == .connected else { return }

        guard let data = command.data(using: .utf8) else { return }
        print("BLE Sending: \(command.trimmingCharacters(in: .whitespacesAndNewlines))")

        let writeType: CBCharacteristicWriteType =
            characteristic.properties.contains(.write) ? .withResponse : .withoutResponse
        peripheral.writeValue(data, for: characteristic, type: writeType)
    }

    // MARK: - Scanning

    func startScanning() {
        guard centralManager?.state == .poweredOn else { return }
        discoveredPeripherals.removeAll()
        retainedPeripherals.removeAll()
        isScanning = true
        centralManager?.scanForPeripherals(withServices: [serviceUUID], options: nil)

        // Auto-stop after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            if self?.isScanning == true {
                self?.stopScanning()
            }
        }
    }

    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
    }

    // MARK: - Private

    private func cleanup() {
        connectedPeripheral = nil
        writeCharacteristic = nil
        notifyCharacteristic = nil
        responseBuffer = ""
    }

    private func handleNotificationData(_ data: Data) {
        guard let chunk = String(data: data, encoding: .utf8) else { return }
        responseBuffer.append(chunk)

        // Deliver complete responses delimited by ">" prompt
        while let promptIndex = responseBuffer.firstIndex(of: ">") {
            let response = String(responseBuffer[responseBuffer.startIndex..<promptIndex])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            responseBuffer = String(responseBuffer[responseBuffer.index(after: promptIndex)...])

            if !response.isEmpty {
                print("BLE Response: \(response)")
                DispatchQueue.main.async {
                    self.delegate?.transport(self, didReceiveData: response)
                }
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension BLETransport: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.bluetoothState = central.state
        }
        if central.state != .poweredOn {
            stopScanning()
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Retain the peripheral and add to discovered list if not already present
        if !retainedPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            retainedPeripherals.append(peripheral)
            DispatchQueue.main.async {
                self.discoveredPeripherals.append(peripheral)
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        cleanup()
        state = .failed(error?.localizedDescription)
        DispatchQueue.main.async {
            self.delegate?.transport(self, didChangeState: .failed(error?.localizedDescription))
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        cleanup()
        state = .disconnected
        DispatchQueue.main.async {
            self.delegate?.transport(self, didChangeState: .disconnected)
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLETransport: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == serviceUUID }) else {
            let msg = String(localized: "OBD service not found")
            state = .failed(msg)
            delegate?.transport(self, didChangeState: .failed(msg))
            centralManager?.cancelPeripheralConnection(peripheral)
            return
        }
        peripheral.discoverCharacteristics([notifyCharUUID, writeCharUUID], for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            let msg = String(localized: "Characteristics not found")
            state = .failed(msg)
            delegate?.transport(self, didChangeState: .failed(msg))
            return
        }

        for characteristic in characteristics {
            if characteristic.uuid == notifyCharUUID {
                notifyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == writeCharUUID {
                writeCharacteristic = characteristic
            }
        }

        // Connected once we have both characteristics
        if writeCharacteristic != nil && notifyCharacteristic != nil {
            state = .connected
            DispatchQueue.main.async {
                self.delegate?.transport(self, didChangeState: .connected)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic.uuid == notifyCharUUID, let data = characteristic.value else { return }
        handleNotificationData(data)
    }
}
