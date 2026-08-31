#if os(macOS)
import SwiftUI
import SentinelCore

struct DashboardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 26) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(model.text(.sentryMode))
                            .font(.system(size: 30, weight: .semibold, design: .rounded))
                        Text(model.text(.lockInstruction))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    statusPill
                }

                EyeView(
                    model: model.eye,
                    trackingEnabled: model.settings.cursorTrackingEnabled,
                    intensity: model.settings.animationIntensity
                )
                .frame(width: 310, height: 310)
                .padding(.vertical, 4)

                if let remaining = model.countdownRemaining {
                    VStack(spacing: 12) {
                        Text("\(remaining)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        HStack {
                            Button(model.text(.enterNow)) { model.enterSentryNow() }
                                .buttonStyle(.borderedProminent)
                            Button(model.text(.cancel)) { model.cancelCountdown() }
                        }
                    }
                } else {
                    Button {
                        model.isArmed ? model.stopSentry() : model.startSentry()
                    } label: {
                        Label(
                            model.isArmed ? model.text(.stopSentry) : model.text(.startSentry),
                            systemImage: model.isArmed ? "shield.slash" : "lock.shield"
                        )
                        .frame(minWidth: 190)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                }

                if let error = model.lastRuntimeError {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                        Text(error)
                        Spacer()
                        if !model.accessibilityTrusted {
                            Button(model.text(.openAccessibility)) { model.openAccessibilitySettings() }
                        }
                    }
                    .padding(14)
                    .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                }

                recentEvents
            }
            .padding(28)
            .frame(maxWidth: 920)
            .frame(maxWidth: .infinity)
        }
    }

    private var statusPill: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(model.isArmed ? Color.green : Color.secondary)
                .frame(width: 8, height: 8)
            Text(model.statusText())
                .font(.callout.weight(.medium))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.thinMaterial, in: Capsule())
    }

    private var recentEvents: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(model.text(.recentEvents))
                    .font(.headline)
                Spacer()
                NavigationLink(model.text(.events)) { EventsView(model: model) }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }

            if model.events.isEmpty {
                Text(model.text(.noEvents))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
            } else {
                ForEach(model.events.prefix(5)) { event in
                    HStack(spacing: 12) {
                        Image(systemName: icon(for: event.type))
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.eventTitle(event))
                            Text(EventPresentation.relativeTime(for: event.timestamp, language: model.settings.language))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    if event.id != model.events.prefix(5).last?.id { Divider() }
                }
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func icon(for type: SentinelCore.SentryEventType) -> String {
        switch type {
        case .networkConnected, .networkDisconnected: return "wifi"
        case .powerConnected, .powerDisconnected: return "bolt"
        case .usbChanged: return "externaldrive"
        case .authenticationFailed, .authenticationAlert: return "person.badge.key"
        case .authenticationSucceeded: return "checkmark.circle"
        case .systemSleeping, .systemWoke: return "moon.zzz"
        case .monitoringInterrupted, .monitoringRecoveryFailed: return "exclamationmark.shield"
        case .monitoringRecovered: return "checkmark.shield"
        case .sessionLocked, .sessionUnlocked: return "lock"
        case .sentryArmed, .sentryDisarmed: return "shield"
        }
    }
}
#endif
