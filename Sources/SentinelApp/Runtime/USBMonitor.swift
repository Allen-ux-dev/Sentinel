#if os(macOS)
import Foundation
import IOKit

@MainActor
final class USBMonitor {
    private var timer: Timer?
    private var lastIDs: Set<UInt64> = []

    func start(handler: @escaping () -> Void) {
        stop()
        lastIDs = snapshot()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            guard let self else { return }
            let current = self.snapshot()
            if current != self.lastIDs {
                self.lastIDs = current
                handler()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func snapshot() -> Set<UInt64> {
        guard let matching = IOServiceMatching("IOUSBHostDevice") else { return [] }
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { return [] }
        defer { IOObjectRelease(iterator) }

        var result = Set<UInt64>()
        var service = IOIteratorNext(iterator)
        while service != 0 {
            var entryID: UInt64 = 0
            if IORegistryEntryGetRegistryEntryID(service, &entryID) == KERN_SUCCESS {
                result.insert(entryID)
            }
            IOObjectRelease(service)
            service = IOIteratorNext(iterator)
        }
        return result
    }
}
#endif
