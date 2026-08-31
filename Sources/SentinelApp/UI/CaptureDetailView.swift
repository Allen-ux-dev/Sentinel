#if os(macOS)
import SwiftUI
import AppKit
import SentinelCore

struct CaptureDetailView: View {
    @ObservedObject var model: AppModel
    let record: CaptureRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.text(.captureDetail))
                        .font(.title2.bold())
                    Text(record.timestamp.formatted(date: .abbreviated, time: .standard))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(role: .destructive) {
                    model.deleteCapture(record)
                    dismiss()
                } label: {
                    Label(model.text(.deleteCapture), systemImage: "trash")
                }
            }

            captureImage
                .frame(maxWidth: .infinity, maxHeight: 520)
                .background(.black.opacity(0.88), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                GridRow {
                    Text(model.text(.capturedAt)).foregroundStyle(.secondary)
                    Text(record.timestamp.formatted(date: .long, time: .standard))
                }
                GridRow {
                    Text(model.text(.unknownAuthentication)).foregroundStyle(.secondary)
                    Text(authenticationLabel)
                }
                GridRow {
                    Text(model.text(.imageDimensions)).foregroundStyle(.secondary)
                    Text("\(record.width) × \(record.height)")
                }
                GridRow {
                    Text(model.text(.fileSize)).foregroundStyle(.secondary)
                    Text(ByteCountFormatter.string(fromByteCount: Int64(record.byteCount), countStyle: .file))
                }
            }

            Text(model.text(.localOnlyCaptureNotice))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(minWidth: 680, minHeight: 620)
    }

    @ViewBuilder
    private var captureImage: some View {
        if let image = NSImage(contentsOf: model.captureImageURL(for: record)) {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            VStack(spacing: 10) {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.system(size: 36))
                Text(model.text(.captureFailed))
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
