import SwiftUI

// MARK: - SessionListView

/// Searchable, pull-to-refresh list of all KarnEvil9 sessions
/// with navigation to detail and new session creation.
struct SessionListView: View {

    // MARK: - State

    @State var viewModel: SessionListViewModel
    @State private var showingNewSession = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.filteredSessions.isEmpty && !viewModel.isLoading {
                    emptyStateView
                } else {
                    sessionsList
                }
            }
            .navigationTitle("Sessions")
            .searchable(text: $viewModel.searchText, prompt: "Search tasks...")
            .refreshable {
                await viewModel.loadSessions()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewSession = true
                    } label: {
                        Label("New Session", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewSession) {
                NewSessionView(
                    viewModel: NewSessionViewModel(client: viewModel.client),
                    onCreated: { _ in
                        showingNewSession = false
                        Task { await viewModel.loadSessions() }
                    }
                )
            }
            .task {
                await viewModel.loadSessions()
            }
            .overlay {
                if viewModel.isLoading && viewModel.sessions.isEmpty {
                    ProgressView("Loading sessions...")
                }
            }
        }
    }

    // MARK: - List

    private var sessionsList: some View {
        List(viewModel.filteredSessions) { session in
            NavigationLink {
                SessionDetailView(
                    session: session,
                    client: viewModel.client
                )
            } label: {
                sessionRow(session)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Row

    private func sessionRow(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.task)
                    .font(.subheadline)
                    .lineLimit(2)
                Spacer()
                sessionStateBadge(session.state)
            }

            Text(session.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - State Badge

    private func sessionStateBadge(_ state: SessionState) -> some View {
        Text(state.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(.white)
            .background(badgeColor(for: state))
            .clipShape(Capsule())
    }

    private func badgeColor(for state: SessionState) -> Color {
        switch state {
        case .running: return .green
        case .planning: return .purple
        case .live: return .green
        case .paused: return .yellow
        case .failed: return .red
        case .completed: return .blue
        case .aborted: return .red
        case .unknown: return .gray
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Sessions", systemImage: "tray")
        } description: {
            Text("Create a new session to get started.")
        } actions: {
            Button("New Session") {
                showingNewSession = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Preview

#Preview {
    SessionListView(
        viewModel: SessionListViewModel(client: KarnEvil9Client(serverConfig: .default))
    )
}
