#if os(macOS)
import SwiftUI

private enum RootSection: String, Hashable, CaseIterable {
    case dashboard
    case events
    case captures
    case settings
    case diagnostics
}

struct RootView: View {
    @ObservedObject var model: AppModel
    @State private var selection: RootSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label(model.text(.dashboard), systemImage: "shield")
                    .tag(RootSection.dashboard)
                Label(model.text(.events), systemImage: "clock.arrow.circlepath")
                    .tag(RootSection.events)
                Label(model.text(.captures), systemImage: "camera.viewfinder")
                    .tag(RootSection.captures)
                Label(model.text(.settings), systemImage: "slider.horizontal.3")
                    .tag(RootSection.settings)
                Label(model.text(.diagnostics), systemImage: "waveform.path.ecg")
                    .tag(RootSection.diagnostics)
            }
            .navigationTitle(model.text(.appName))
            .frame(minWidth: 210)
        } detail: {
            switch selection ?? .dashboard {
            case .dashboard: DashboardView(model: model)
            case .events: EventsView(model: model)
            case .captures: CapturesView(model: model)
            case .settings: SettingsView(model: model)
            case .diagnostics: DiagnosticsView(model: model)
            }
        }
    }
}
#endif
