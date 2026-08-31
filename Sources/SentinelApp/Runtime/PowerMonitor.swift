#if os(macOS)
import Foundation
import IOKit.ps

@MainActor
final class PowerMonitor {
    private var timer: Timer?
    private var lastACConnected: Bool?

    func start(handler: @escaping (Bool) -> Void) {
        stop()
        lastACConnected = readACConnected()
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            guard let self else { return }
            let current = self.readACConnected()
            if let previous = self.lastACConnected, let current, previous != current {
                handler(current)
            }
            if let current { self.lastACConnected = current }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func readACConnected() -> Bool? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let rawList = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef]
        else { return nil }

        for source in rawList {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  let state = description[kIOPSPowerSourceStateKey as String] as? String
            else { continue }
            return state == (kIOPSACPowerValue as String)
        }
        return nil
    }
}
#endif
