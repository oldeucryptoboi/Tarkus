import SwiftUI

// MARK: - AppTabView

/// Root tab view that provides top-level navigation between the four main
/// sections of the Tarkus app: Dashboard, Approvals, Sessions, and Settings.
struct AppTabView: View {

    // MARK: - Dependencies

    /// The KarnEvil9 API client, passed down from `TarkusApp`.
    let client: KarnEvil9Client

    // MARK: - Environment

    @Environment(AppRouter.self) private var appRouter

    // MARK: - Body

    var body: some View {
        @Bindable var router = appRouter

        TabView(selection: $router.selectedTab) {
            dashboardTab
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.open.with.lines.needle.33percent")
                }
                .tag(0)

            approvalsTab
                .tabItem {
                    Label("Approvals", systemImage: "checkmark.shield")
                }
                .tag(1)
                .badge(appRouter.approvalsBadgeCount)

            sessionsTab
                .tabItem {
                    Label("Sessions", systemImage: "list.bullet.rectangle")
                }
                .tag(2)

            settingsTab
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }

    // MARK: - Tab Content

    private var dashboardTab: some View {
        let sseClient = SSEClient(serverConfig: client.serverConfig)
        let viewModel = DashboardViewModel(client: client, sseClient: sseClient)
        return DashboardView(viewModel: viewModel)
    }

    private var approvalsTab: some View {
        ApprovalsListView(viewModel: ApprovalsViewModel(client: client))
    }

    private var sessionsTab: some View {
        SessionListView(viewModel: SessionListViewModel(client: client))
    }

    private var settingsTab: some View {
        SettingsView(viewModel: SettingsViewModel(client: client))
    }
}

// MARK: - Preview

#Preview {
    let config = ServerConfig(host: "localhost", port: 3100)
    let client = KarnEvil9Client(serverConfig: config)

    AppTabView(client: client)
        .environment(AppRouter())
}
