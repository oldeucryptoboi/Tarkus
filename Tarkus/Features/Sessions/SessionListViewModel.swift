import Foundation

// MARK: - SessionListViewModel

/// ViewModel for the session list screen, supporting search filtering
/// and pull-to-refresh loading.
@Observable
class SessionListViewModel {

    // MARK: - Properties

    var sessions: [Session] = []
    var isLoading: Bool = false
    var searchText: String = ""
    var errorMessage: String?

    // MARK: - Dependencies

    let client: KarnEvil9Client

    // MARK: - Initialization

    init(client: KarnEvil9Client) {
        self.client = client
    }

    // MARK: - Computed Properties

    /// Sessions filtered by the current search text, matching against
    /// the task description. Returns all sessions when search is empty.
    var filteredSessions: [Session] {
        guard !searchText.isEmpty else { return sessions }
        return sessions.filter {
            $0.task.localizedCaseInsensitiveContains(searchText)
        }
    }

    // MARK: - Actions

    /// Fetches the full list of sessions from the server.
    @MainActor
    func loadSessions() async {
        isLoading = true
        errorMessage = nil

        do {
            // Filter out plugin registrations (non-UUID IDs, empty tasks, unknown status)
            sessions = try await client.listSessions()
                .filter { !$0.task.isEmpty && $0.state != .unknown }
                .sorted {
                    // Active sessions first, then by most recently updated
                    if $0.state.isActive != $1.state.isActive {
                        return $0.state.isActive
                    }
                    return $0.updatedAt > $1.updatedAt
                }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
