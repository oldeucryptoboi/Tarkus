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
    func startMonitoring(session: Session) async {
        stopMonitoring()
        isLoading = true
        errorMessage = nil

        // Use the passed session directly (avoids 404 from getSession
        // when the in-memory session manager no longer has the session).
        currentSession = session

        do {
            events = try await client.getSessionJournal(id: session.id)
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

            let stream = self.sseClient.connect(sessionId: session.id)

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
        currentSession?.state = .aborted
    }

    /// Sends a recovery request for the currently monitored session.
    @MainActor
    func recoverSession() async throws {
        guard let sessionId = currentSession?.id else { return }
        try await client.recoverSession(id: sessionId)
        currentSession?.state = .running
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: KarnEvil9Event) {
        switch event {
        case .sessionEvent(let journalEvent):
            events.append(journalEvent)
            // Update session state locally from terminal events
            if journalEvent.type == "session.completed" ||
               journalEvent.type == "session.failed" ||
               journalEvent.type == "session.aborted" {
                isConnected = false
                if var session = currentSession {
                    session.state = SessionState(rawValue: journalEvent.type
                        .replacingOccurrences(of: "session.", with: "")) ?? session.state
                    session.updatedAt = journalEvent.timestamp
                    currentSession = session
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
