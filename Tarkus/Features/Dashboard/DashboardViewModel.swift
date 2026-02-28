import Foundation

// MARK: - DashboardViewModel

/// ViewModel that drives live session monitoring on the Dashboard.
/// Connects to the SSE stream for a given session and translates events
/// into UI state.
@Observable
class DashboardViewModel {

    // MARK: - Properties

    var currentSession: Session?
    var events: [JournalEvent] = []
    var isConnected: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    var pendingApprovals: Int = 0

    // MARK: - Dependencies

    private let client: KarnEvil9Client
    private let sseClient: SSEClient
    private var monitoringTask: Task<Void, Never>?

    // MARK: - Initialization

    init(client: KarnEvil9Client, sseClient: SSEClient) {
        self.client = client
        self.sseClient = sseClient
    }

    // MARK: - Monitoring

    /// Begins monitoring a session by connecting to its SSE event stream
    /// and updating the dashboard state in response to incoming events.
    @MainActor
    func startMonitoring(sessionId: String) async {
        stopMonitoring()
        isLoading = true
        errorMessage = nil

        // Fetch the initial session state
        do {
            currentSession = try await client.getSession(id: sessionId)
            events = try await client.getSessionJournal(id: sessionId)
            isConnected = true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return
        }

        isLoading = false

        // Start streaming events
        monitoringTask = Task { [weak self] in
            guard let self else { return }

            let stream = self.sseClient.connect(sessionId: sessionId)

            for await event in stream {
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    self.handleEvent(event)
                }
            }

            await MainActor.run {
                self.isConnected = false
            }
        }
    }

    /// Stops the current monitoring session and disconnects the SSE stream.
    func stopMonitoring() {
        monitoringTask?.cancel()
        monitoringTask = nil
        sseClient.disconnect()
        isConnected = false
    }

    // MARK: - Session Actions

    /// Sends an abort request for the currently monitored session.
    @MainActor
    func abortSession() async throws {
        guard let sessionId = currentSession?.id else { return }
        try await client.abortSession(id: sessionId)
        currentSession = try await client.getSession(id: sessionId)
    }

    /// Sends a recovery request for the currently monitored session.
    @MainActor
    func recoverSession() async throws {
        guard let sessionId = currentSession?.id else { return }
        try await client.recoverSession(id: sessionId)
        currentSession = try await client.getSession(id: sessionId)
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: KarnEvil9Event) {
        switch event {
        case .sessionEvent(let journalEvent):
            events.append(journalEvent)
            // Refresh session state on terminal events
            if journalEvent.type == "session.completed" ||
               journalEvent.type == "session.failed" ||
               journalEvent.type == "session.aborted" {
                isConnected = false
                Task {
                    currentSession = try? await client.getSession(id: journalEvent.sessionId)
                }
            } else {
                Task {
                    currentSession = try? await client.getSession(id: journalEvent.sessionId)
                }
            }

        case .stepEvent(let journalEvent):
            events.append(journalEvent)

        case .plannerEvent(let journalEvent):
            events.append(journalEvent)

        case .approvalEvent(let journalEvent):
            events.append(journalEvent)
            if journalEvent.type == "approval.requested" {
                pendingApprovals += 1
            } else if journalEvent.type == "approval.resolved" {
                pendingApprovals = max(0, pendingApprovals - 1)
            }

        case .error(message: let message):
            errorMessage = message

        case .unknown(let journalEvent):
            events.append(journalEvent)
        }
    }
}
