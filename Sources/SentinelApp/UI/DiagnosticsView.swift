#if os(macOS)
import SwiftUI
import SentinelCore

struct DiagnosticsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(model.text(.diagnostics))
                    .font(.largeTitle.bold())

                diagnosticRow(
                    title: model.text(.monitoringHealthy),
                    value: model.isArmed ? model.text(.armed) : model.text(.disarmed),
                    ok: true
                )
                diagnosticRow(
                    title: model.text(.accessibility),
                    value: model.accessibilityTrusted ? model.text(.okay) : model.text(.accessibilityRequired),
                    ok: model.accessibilityTrusted
                )
                diagnosticRow(
                    title: model.text(.experimentalAuth),
                    value: model.authMonitorAvailable ? model.text(.active) : model.text(.authExperimentalUnavailable),
                    ok: model.authMonitorAvailable
                )
                diagnosticRow(
                    title: model.text(.watchdog),
                    value: helperDescription,
                    ok: model.helperStatus?.state != .recoveryFailed && model.helperStatus?.state != .recoveryBlocked
                )

                Divider()

                HStack {
                    Button(model.text(.simulatePasswordFailure)) { model.simulateAuthenticationFailure(kind: .password) }
                    Button(model.text(.simulateTouchIDFailure)) { model.simulateAuthenticationFailure(kind: .touchID) }
                    Button(model.text(.debugAuthSuccess)) { model.simulateAuthenticationSuccess() }
                }
                Text(model.text(.authExperimentalUnavailable))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(28)
            .frame(maxWidth: 760, alignment: .leading)
        }
    }

    private var helperDescription: String {
        guard let status = model.helperStatus else { return model.text(.noStatusYet) }
        let state: String
        switch status.state {
        case .idle: state = model.text(.helperIdle)
        case .healthy: state = model.text(.helperHealthy)
        case .recoveryAttempted: state = model.text(.helperRecoveryAttempted)
        case .recoveryBlocked: state = model.text(.helperRecoveryBlocked)
        case .recoveryFailed: state = model.text(.helperRecoveryFailed)
        }
        return "\(state) · \(status.recoveryAttemptsInWindow) \(model.text(.attempts))"
    }

    private func diagnosticRow(title: String, value: String, ok: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(ok ? .green : .orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(value).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
#endif
