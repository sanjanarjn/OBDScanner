import Foundation
import Network

class WiFiTransport: OBDTransport {
    weak var delegate: OBDTransportDelegate?
    private(set) var state: TransportState = .disconnected

    private var connection: NWConnection?
    private let host: String
    private let port: UInt16

    init(host: String = "192.168.0.10", port: UInt16 = 35000) {
        self.host = host
        self.port = port
    }

    func connect() {
        let nwHost = NWEndpoint.Host(host)
        let nwPort = NWEndpoint.Port(rawValue: port)!

        state = .connecting
        delegate?.transport(self, didChangeState: .connecting)

        connection = NWConnection(host: nwHost, port: nwPort, using: .tcp)
        connection?.stateUpdateHandler = { [weak self] nwState in
            guard let self = self else { return }
            switch nwState {
            case .ready:
                self.state = .connected
                DispatchQueue.main.async {
                    self.delegate?.transport(self, didChangeState: .connected)
                }
                self.startListening()
            case .failed(let error):
                self.state = .failed(error.localizedDescription)
                DispatchQueue.main.async {
                    self.delegate?.transport(self, didChangeState: .failed(error.localizedDescription))
                }
            case .cancelled:
                self.state = .disconnected
                DispatchQueue.main.async {
                    self.delegate?.transport(self, didChangeState: .disconnected)
                }
            case .waiting:
                // Connection can't be established — clean up
                self.connection?.cancel()
                self.state = .failed("Network unavailable")
                DispatchQueue.main.async {
                    self.delegate?.transport(self, didChangeState: .failed("Network unavailable"))
                }
            default:
                break
            }
        }

        connection?.start(queue: .global())
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
        state = .disconnected
        delegate?.transport(self, didChangeState: .disconnected)
    }

    func send(_ command: String) {
        guard let connection = connection, state == .connected else { return }
        let data = command.data(using: .utf8)!
        print("Sending: \(command.trimmingCharacters(in: .whitespacesAndNewlines))")
        connection.send(content: data, completion: .contentProcessed({ _ in }))
    }

    private func startListening() {
        guard let connection = connection, state == .connected else { return }
        connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { [weak self] data, _, _, _ in
            guard let self = self, self.state == .connected else { return }
            if let data = data, let response = String(data: data, encoding: .utf8) {
                let cleanResponse = response.trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleanResponse.isEmpty {
                    DispatchQueue.main.async {
                        self.delegate?.transport(self, didReceiveData: cleanResponse)
                    }
                }
            }
            self.startListening()
        }
    }
}
