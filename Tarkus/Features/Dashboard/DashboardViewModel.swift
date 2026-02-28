import Foundation

// MARK: - DashboardViewModel

/// ViewModel that drives live session monitoring on the Dashboard.
/// Connects to the SSE stream for a given session and translates events
/// into UI state.
@Observable
class DashboardViewModel {

    // MARK: - Properties

    var currentSession: Session?
    var steps: [Step] = []
    var isConnected: Bool = false
    var isLoading: Bool = false
    var errorMessage: String?
    var pendingApprovals: Int = 0
    var metrics: UsageMetrics?

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
            steps = try await client.getSessionJournal(id: sessionId)
            metrics = currentSession?.usage
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
                await self.handleEvent(event)
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

    @MainActor
    private func handleEvent(_ event: KarnEvil9Event) {
        switch event {
        // Session lifecycle
        case .sessionStarted(let session),
             .sessionResumed(let session),
             .sessionPaused(let session):
            currentSession = session

        case .sessionCompleted(let session):
            currentSession = session
            isConnected = false

        case .sessionFailed(let session):
            currentSession = session
            isConnected = false

        case .sessionAborted(let session):
            currentSession = session
            isConnected = false

        // Step lifecycle
        case .stepStarted(let step):
            steps.append(step)

        case .stepCompleted(let step):
            if let index = steps.firstIndex(where: { $0.id == step.id }) {
                steps[index] = step
            } else {
                steps.append(step)
            }

        case .stepFailed(let step):
            if let index = steps.firstIndex(where: { $0.id == step.id }) {
                steps[index] = step
            } else {
                steps.append(step)
            }

        // Tool execution
        case .toolCallStarted:
            break // Tool calls are tracked via step events

        case .toolResultReceived:
            break // Tool results are tracked via step events

        // Assistant output
        case .assistantMessage:
            break // Could be displayed in a future detail view

        // Permissions
        case .permissionRequested:
            pendingApprovals += 1

        case .permissionResolved:
            pendingApprovals = max(0, pendingApprovals - 1)

        // Metrics
        case .usageUpdated(let updatedMetrics):
            metrics = updatedMetrics

        // Error
        case .error(message: let message):
            errorMessage = message

        // Heartbeat
        case .heartbeat:
            break
        }
    }
}
