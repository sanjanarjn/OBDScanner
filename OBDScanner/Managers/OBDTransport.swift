import Foundation

// MARK: - Transport State

enum TransportState: Equatable {
    case disconnected
    case connecting
    case connected
    case failed(String?)

    static func == (lhs: TransportState, rhs: TransportState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected):
            return true
        case (.failed(let a), .failed(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Connection Type

enum ConnectionType: String, CaseIterable {
    case wifi = "WiFi"
    case ble = "BLE"
}

// MARK: - Transport Delegate

protocol OBDTransportDelegate: AnyObject {
    func transport(_ transport: OBDTransport, didChangeState state: TransportState)
    func transport(_ transport: OBDTransport, didReceiveData data: String)
}

// MARK: - Transport Protocol

protocol OBDTransport: AnyObject {
    var delegate: OBDTransportDelegate? { get set }
    var state: TransportState { get }
    func connect()
    func disconnect()
    func send(_ command: String)
}
