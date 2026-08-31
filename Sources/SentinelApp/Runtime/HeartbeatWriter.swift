#if os(macOS)
import Foundation
import SentinelCore

@MainActor
final class HeartbeatWriter {
    private let runtimeStore: SharedRuntimeStore
    private var timer: Timer?

    init(runtimeStore: SharedRuntimeStore) {
        self.runtimeStore = runtimeStore
    }

    func start() {
        stop()
        writeNow()
        timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.writeNow()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func writeNow() {
        try? runtimeStore.writeHeartbeat(HeartbeatSnapshot(timestamp: Date(), processID: ProcessInfo.processInfo.processIdentifier))
    }
}
#endif
