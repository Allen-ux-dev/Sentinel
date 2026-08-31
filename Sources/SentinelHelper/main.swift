#if os(macOS)
import Foundation
import SentinelCore
do {
    let runtime = try SharedRuntimeStore(directory: SharedRuntimeStore.defaultDirectory())
    let loop = WatchdogLoop(runtimeStore: runtime)
    loop.run()
} catch {
    fputs("SentinelHelper failed to initialize: \(error)\n", stderr)
    exit(1)
}
#endif
