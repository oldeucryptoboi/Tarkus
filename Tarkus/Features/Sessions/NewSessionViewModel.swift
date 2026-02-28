import Foundation

// MARK: - NewSessionViewModel

/// ViewModel for the new session creation sheet.
/// Manages task input and session creation.
@Observable
class NewSessionViewModel {

    // MARK: - Properties

    var task: String = ""
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

    /// Creates a new session with the current task text.
    /// Returns the newly created session on success.
    @MainActor
    func createSession() async throws -> Session {
        isLoading = true
        errorMessage = nil

        do {
            let request = CreateSessionRequest(
                text: task.trimmingCharacters(in: .whitespacesAndNewlines)
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
