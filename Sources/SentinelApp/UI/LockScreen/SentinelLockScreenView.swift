#if os(macOS)
import SwiftUI

struct SentinelLockScreenView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            Color.clear
            VStack(spacing: 14) {
                EyeView(
                    model: model.eye,
                    trackingEnabled: model.settings.cursorTrackingEnabled,
                    intensity: model.settings.animationIntensity
                )
                .frame(width: 230, height: 230)

                VStack(spacing: 5) {
                    Text(model.text(.sentryMode))
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    Text(model.statusText())
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                if model.settings.showRecentEventsOnLockScreen {
                    VStack(spacing: 6) {
                        ForEach(model.events.prefix(3)) { event in
                            Text("\(model.eventTitle(event)) · \(EventPresentation.relativeTime(for: event.timestamp, language: model.settings.language))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, 42)
            .padding(.vertical, 26)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
#endif
