#if os(macOS)
import Foundation
import SentinelCore

final class ExperimentalSystemLogAuthMonitor: AuthenticationOutcomeMonitor {
    private var process: Process?
    private var pipe: Pipe?
    private var lineBuffer = ""
    private var handler: ((AuthenticationOutcome) -> Void)?
    private(set) var isAvailable: Bool = false

    func start(handler: @escaping (AuthenticationOutcome) -> Void) {
        stop()
        self.handler = handler
        guard FileManager.default.isExecutableFile(atPath: "/usr/bin/log") else {
            isAvailable = false
            return
        }

        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        process.arguments = [
            "stream",
            "--style", "json",
            "--level", "default",
            "--predicate",
            "(process == \"loginwindow\" OR subsystem BEGINSWITH \"com.apple.LocalAuthentication\") AND eventMessage CONTAINS[c] \"auth\""
        ]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            guard let self else { return }
            let data = handle.availableData
            guard !data.isEmpty, let chunk = String(data: data, encoding: .utf8) else { return }
            self.consume(chunk)
        }

        do {
            try process.run()
            self.process = process
            self.pipe = pipe
            isAvailable = process.isRunning
        } catch {
            pipe.fileHandleForReading.readabilityHandler = nil
            isAvailable = false
        }
    }

    func stop() {
        pipe?.fileHandleForReading.readabilityHandler = nil
        if process?.isRunning == true { process?.terminate() }
        process = nil
        pipe = nil
        lineBuffer = ""
        isAvailable = false
    }

    private func consume(_ chunk: String) {
        lineBuffer += chunk
        let lines = lineBuffer.split(separator: "\n", omittingEmptySubsequences: false)
        guard lines.count > 1 else { return }
        lineBuffer = String(lines.last ?? "")
        for line in lines.dropLast() {
            let lower = line.lowercased()
            let mentionsAuthentication = lower.contains("auth")
            let failed = lower.contains("failed") || lower.contains("failure") || lower.contains("denied")
            if mentionsAuthentication && failed {
                DispatchQueue.main.async { [weak self] in self?.handler?(.failed(.unknown)) }
            }
        }
    }
}
#endif
