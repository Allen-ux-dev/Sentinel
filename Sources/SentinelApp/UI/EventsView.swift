#if os(macOS)
import SwiftUI
import SentinelCore

struct EventsView: View {
    @ObservedObject var model: AppModel
    @State private var selectedCapture: CaptureRecord?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(model.text(.events))
                    .font(.largeTitle.bold())
                Spacer()
                Button(role: .destructive) { model.clearHistory() } label: {
                    Label(model.text(.clearHistory), systemImage: "trash")
                }
                .disabled(model.events.isEmpty)
            }
            .padding(24)

            Divider()

            if model.events.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 34))
                        .foregroundStyle(.secondary)
                    Text(model.text(.noEvents))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(model.events) { event in
                    HStack(alignment: .top, spacing: 14) {
                        Circle()
                            .fill(color(for: event.severity))
                            .frame(width: 9, height: 9)
                            .padding(.top, 6)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(model.eventTitle(event))
                                .font(.body.weight(.medium))
                            Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if let detail = event.detail, !detail.isEmpty, event.type != .authenticationFailed {
                                Text(detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            captureAction(for: event)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 5)
                }
            }
        }
        .sheet(item: $selectedCapture) { record in
            CaptureDetailView(model: model, record: record)
        }
    }

    @ViewBuilder
    private func captureAction(for event: SentryEvent) -> some View {
        if event.type == .authenticationFailed {
            switch event.captureState {
            case .some(.pending):
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small)
                    Text(model.text(.capturePending))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            case .some(.available):
                if let id = event.captureID, let record = model.captureRecord(id: id) {
                    Button(model.text(.viewCapture)) {
                        selectedCapture = record
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            case .some(.failed):
                Label(model.text(.captureFailed), systemImage: "camera.badge.ellipsis")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .none:
                EmptyView()
            }
        }
    }

    private func color(for severity: SentrySeverity) -> Color {
        switch severity {
        case .info: return .secondary
        case .notice: return .orange
        case .alert: return .red
        }
    }
}
#endif
