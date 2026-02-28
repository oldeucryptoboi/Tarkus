import Foundation

// MARK: - NewSessionViewModel

/// ViewModel for the new session creation sheet.
/// Manages task input, optional plugin selection, and session creation.
@Observable
class NewSessionViewModel {

    // MARK: - Properties

    var task: String = ""
    var selectedPlugin: String?
    var plugins: [PluginInfo] = []
    var isLoading: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let client: KarnEvil9Client

    // MARK: - Initialization

    init(client: KarnEvil9Client) {
        self.client = client
    }

    // MARK: - Computed Properties

    /// Whether the form has enough input to create a session.
    var canCreate: Bool {
        !task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    /// Fetches the list of available plugins from the server.
    @MainActor
    func loadPlugins() async {
        do {
            plugins = try await client.listPlugins()
        } catch {
            // Plugin loading failure is non-critical; the list remains empty
            plugins = []
        }
    }

    /// Creates a new session with the current task and optional plugin.
    /// Returns the newly created session on success.
    @MainActor
    func createSession() async throws -> Session {
        isLoading = true
        errorMessage = nil

        do {
            let request = CreateSessionRequest(
                task: task.trimmingCharacters(in: .whitespacesAndNewlines),
                plugin: selectedPlugin,
                allowedTools: nil
            )
            let session = try await client.createSession(request)
            isLoading = false
            return session
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            throw error
        }
    }
}
