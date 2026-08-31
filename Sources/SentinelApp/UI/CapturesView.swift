#if os(macOS)
import SwiftUI
import AppKit
import SentinelCore

struct CapturesView: View {
    @ObservedObject var model: AppModel
    @State private var selectedCapture: CaptureRecord?

    private let columns = [GridItem(.adaptive(minimum: 220, maximum: 320), spacing: 16)]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.text(.captures))
                        .font(.largeTitle.bold())
                    Text(model.text(.localOnlyCaptureNotice))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive) { model.clearCaptures() } label: {
                    Label(model.text(.clearCaptures), systemImage: "trash")
                }
                .disabled(model.captures.isEmpty)
            }
            .padding(24)

            Divider()

            if model.captures.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary)
                    Text(model.text(.noCaptures))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(model.captures) { record in
                            Button {
                                selectedCapture = record
                            } label: {
                                CaptureCard(model: model, record: record)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(24)
                }
            }
        }
        .sheet(item: $selectedCapture) { record in
            CaptureDetailView(model: model, record: record)
        }
    }
}

private struct CaptureCard: View {
    @ObservedObject var model: AppModel
    let record: CaptureRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if let image = NSImage(contentsOf: model.captureImageURL(for: record)) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Rectangle().fill(.secondary.opacity(0.08))
                        Image(systemName: "photo.badge.exclamationmark")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 150)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(authenticationLabel)
                .font(.body.weight(.semibold))
            Text(record.timestamp.formatted(date: .abbreviated, time: .standard))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(ByteCountFormatter.string(fromByteCount: Int64(record.byteCount), countStyle: .file))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var authenticationLabel: String {
        switch record.authenticationKind {
        case .password: return model.text(.passwordFailure)
        case .touchID: return model.text(.touchIDFailure)
        case .unknown: return model.text(.unknownAuthentication)
        }
    }
}
#endif
