#if os(macOS)
import Foundation
import Network

final class NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "dev.sentinel.network-monitor")
    private var lastConnected: Bool?

    func start(handler: @escaping (Bool) -> Void) {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let connected = path.status == .satisfied
            if let previous = self.lastConnected, previous != connected {
                DispatchQueue.main.async { handler(connected) }
            }
            self.lastConnected = connected
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
#endif
