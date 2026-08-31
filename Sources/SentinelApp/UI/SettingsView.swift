#if os(macOS)
import SwiftUI
import AppKit
import SentinelCore

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Section(model.text(.language)) {
                Picker(model.text(.language), selection: model.binding(\.language)) {
                    Text(model.text(.systemLanguage)).tag(AppLanguage.system)
                    Text(model.text(.chinese)).tag(AppLanguage.zhHans)
                    Text(model.text(.english)).tag(AppLanguage.english)
                }
                .pickerStyle(.segmented)
            }

            Section(model.text(.sentryMode)) {
                Toggle(model.text(.autoArmOnLock), isOn: model.binding(\.autoArmOnLock))
                Picker(model.text(.countdown), selection: model.binding(\.manualActivationCountdown)) {
                    Text("0s").tag(0)
                    Text("3s").tag(3)
                    Text("5s").tag(5)
                    Text("10s").tag(10)
                }
                Toggle(model.text(.showRecentOnLock), isOn: model.binding(\.showRecentEventsOnLockScreen))
                Toggle(model.text(.launchAtLogin), isOn: model.binding(\.launchAtLogin))
            }

            Section(model.text(.alert)) {
                Stepper(value: model.binding(\.authenticationFailureThreshold), in: 2...10) {
                    LabeledContent(model.text(.authThreshold), value: "\(model.settings.authenticationFailureThreshold)")
                }
                Picker(model.text(.authWindow), selection: model.binding(\.authenticationFailureWindow)) {
                    Text("60s").tag(TimeInterval(60))
                    Text("120s").tag(TimeInterval(120))
                    Text("300s").tag(TimeInterval(300))
                }
                Picker(model.text(.highAlertDuration), selection: model.binding(\.highAlertDuration)) {
                    Text("5s").tag(TimeInterval(5))
                    Text("10s").tag(TimeInterval(10))
                    Text("20s").tag(TimeInterval(20))
                }
                Toggle(model.text(.alertSound), isOn: model.binding(\.alertSoundEnabled))
                Toggle(model.text(.experimentalAuth), isOn: model.binding(\.experimentalAuthenticationMonitorEnabled))
            }

            Section(model.text(.captures)) {
                Toggle(
                    model.text(.captureOnAuthFailure),
                    isOn: Binding(
                        get: { model.settings.authenticationFailureCaptureEnabled },
                        set: { model.setAuthenticationFailureCaptureEnabled($0) }
                    )
                )

                LabeledContent(
                    model.text(.cameraPermission),
                    value: model.cameraPermissionGranted ? model.text(.cameraPermissionGranted) : model.text(.cameraPermissionDenied)
                )
                if !model.cameraPermissionGranted {
                    Button(model.text(.requestCameraPermission)) {
                        model.requestCameraPermission()
                    }
                }

                Picker(model.text(.captureQuality), selection: model.binding(\.captureImageQuality)) {
                    Text(model.text(.efficient)).tag(CaptureImageQuality.efficient)
                    Text(model.text(.standard)).tag(CaptureImageQuality.standard)
                    Text(model.text(.highQuality)).tag(CaptureImageQuality.high)
                }

                Picker(model.text(.captureRetention), selection: model.binding(\.captureRetentionDays)) {
                    Text(model.text(.oneDay)).tag(1)
                    Text(model.text(.sevenDays)).tag(7)
                    Text(model.text(.thirtyDays)).tag(30)
                }

                Picker(model.text(.captureStorageLimit), selection: model.binding(\.captureMaxStorageMB)) {
                    Text("50 MB").tag(50)
                    Text("250 MB").tag(250)
                    Text("500 MB").tag(500)
                    Text("1 GB").tag(1024)
                }

                Text(model.text(.localOnlyCaptureNotice))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(role: .destructive) { model.clearCaptures() } label: {
                    Label(model.text(.clearCaptures), systemImage: "trash")
                }
                .disabled(model.captures.isEmpty)
            }

            Section(model.text(.animationIntensity)) {
                Picker(model.text(.animationIntensity), selection: model.binding(\.animationIntensity)) {
                    Text(model.text(.quiet)).tag(AnimationIntensity.quiet)
                    Text(model.text(.standard)).tag(AnimationIntensity.standard)
                    Text(model.text(.lively)).tag(AnimationIntensity.lively)
                }
                Toggle(model.text(.cursorTracking), isOn: model.binding(\.cursorTrackingEnabled))
                Toggle(model.text(.naturalBlink), isOn: model.binding(\.naturalBlinkEnabled))
            }

            Section(model.text(.retention)) {
                Picker(model.text(.retention), selection: model.binding(\.eventRetentionDays)) {
                    Text(model.text(.oneDay)).tag(1)
                    Text(model.text(.sevenDays)).tag(7)
                    Text(model.text(.thirtyDays)).tag(30)
                }
                Button(role: .destructive) { model.clearHistory() } label: {
                    Label(model.text(.clearHistory), systemImage: "trash")
                }
            }

            Section(model.text(.aboutMe)) {
                HStack(spacing: 12) {
                    Image(nsImage: NSApplication.shared.applicationIconImage)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Sentinel")
                            .font(.headline)
                        Text("\(model.text(.developer)): Allen-ux-dev")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Link(destination: URL(string: "https://github.com/Allen-ux-dev")!) {
                    Label(model.text(.githubProfile), systemImage: "link")
                }
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .onAppear { model.refreshCameraPermissionStatus() }
    }
}
#endif
