import SwiftUI

// MARK: - DashboardView

/// Main live monitoring view for an active KarnEvil9 session.
/// Displays session header, event timeline, and optional metrics bar.
struct DashboardView: View {

    // MARK: - State

    @State var viewModel: DashboardViewModel

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if let session = viewModel.currentSession {
                    activeSessionContent(session)
                } else if viewModel.isLoading {
                    ProgressView("Connecting...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("Dashboard")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                if viewModel.currentSession != nil {
                    ToolbarItemGroup(placement: .primaryAction) {
                        toolbarButtons
                    }
                }
            }
            .overlay {
                if let errorMessage = viewModel.errorMessage {
                    errorBanner(errorMessage)
                }
            }
        }
    }

    // MARK: - Active Session

    @ViewBuilder
    private func activeSessionContent(_ session: Session) -> some View {
        VStack(spacing: 0) {
            SessionHeaderView(session: session)

            Divider()

            EventTimelineView(events: viewModel.events)
                .frame(maxHeight: .infinity)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Active Session", systemImage: "bolt.slash")
        } description: {
            Text("Open the Sessions tab to start or select a session to monitor.")
        }
    }

    // MARK: - Toolbar

    @ViewBuilder
    private var toolbarButtons: some View {
        if let session = viewModel.currentSession {
            if session.state.isActive {
                Button {
                    Task {
                        try? await viewModel.abortSession()
                    }
                } label: {
                    Label("Abort", systemImage: "stop.circle")
                }
                .tint(.red)
            }

            if session.state == .failed || session.state == .aborted {
                Button {
                    Task {
                        try? await viewModel.recoverSession()
                    }
                } label: {
                    Label("Recover", systemImage: "arrow.counterclockwise.circle")
                }
                .tint(.orange)
            }
        }
    }

    // MARK: - Error Banner

    private func errorBanner(_ message: String) -> some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text(message)
                    .font(.caption)
                    .lineLimit(2)
                Spacer()
                Button {
                    viewModel.errorMessage = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ServerConfig.default
    let client = KarnEvil9Client(serverConfig: config)
    let sseClient = SSEClient(serverConfig: config)
    DashboardView(viewModel: DashboardViewModel(client: client, sseClient: sseClient))
}
