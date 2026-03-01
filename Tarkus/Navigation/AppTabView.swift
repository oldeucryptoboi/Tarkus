import SwiftUI

// MARK: - AppTabView

/// Root tab view that provides top-level navigation between the four main
/// sections of the Tarkus app: Chat, Activity, Approvals, and Settings.
struct AppTabView: View {

    // MARK: - Dependencies

    /// The KarnEvil9 API client, passed down from `TarkusApp`.
    let client: KarnEvil9Client

    /// The WebSocket client for the chat interface.
    let webSocket: WebSocketClient

    // MARK: - State

    /// Persistent chat view model — survives tab switches.
    @State private var chatViewModel: ChatViewModel

    // MARK: - Environment

    @Environment(AppRouter.self) private var appRouter

    // MARK: - Initialization

    init(client: KarnEvil9Client, webSocket: WebSocketClient) {
        self.client = client
        self.webSocket = webSocket
        _chatViewModel = State(initialValue: ChatViewModel(webSocket: webSocket, client: client))
    }

    // MARK: - Body

    var body: some View {
        @Bindable var router = appRouter

        TabView(selection: $router.selectedTab) {
            ChatView(viewModel: chatViewModel)
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                }
                .tag(0)

            activityTab
                .tabItem {
                    Label("Activity", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            approvalsTab
                .tabItem {
                    Label("Approvals", systemImage: "checkmark.shield")
                }
                .tag(2)
                .badge(appRouter.approvalsBadgeCount)

            settingsTab
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }

    // MARK: - Tab Content

    private var activityTab: some View {
        SessionListView(viewModel: SessionListViewModel(client: client))
    }

    private var approvalsTab: some View {
        ApprovalsListView(viewModel: ApprovalsViewModel(client: client))
    }

    private var settingsTab: some View {
        SettingsView(viewModel: SettingsViewModel(client: client))
    }
}

// MARK: - Preview

#Preview {
    let config = ServerConfig(host: "localhost", port: 3100)
    let client = KarnEvil9Client(serverConfig: config)
    let webSocket = WebSocketClient()

    AppTabView(client: client, webSocket: webSocket)
        .environment(AppRouter())
}
