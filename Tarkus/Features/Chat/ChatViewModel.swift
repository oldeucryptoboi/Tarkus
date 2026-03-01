import Foundation

// MARK: - ChatViewModel

/// Manages chat state and WebSocket event routing for the EDDIE chat interface.
@Observable
@MainActor
class ChatViewModel {

    // MARK: - Properties

    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isConnected: Bool = false

    private let webSocket: WebSocketClient
    private let client: KarnEvil9Client
    private var streamTask: Task<Void, Never>?

    /// Tracks whether we're waiting for a session.created in response to a user submit.
    private var awaitingSessionForSubmit: Bool = false

    /// Session IDs initiated by the user through the chat interface.
    /// Events for other sessions (scheduler, plugins) are ignored.
    private var chatSessionIds: Set<String> = []

    // MARK: - Initialization

    init(webSocket: WebSocketClient, client: KarnEvil9Client) {
        self.webSocket = webSocket
        self.client = client
    }

    // MARK: - Connection

    /// Connects to the WebSocket and begins listening for events.
    func connect() {
        guard let baseURL = client.serverConfig.baseURL else { return }
        let token = try? KeychainService.getToken()

        let stream = webSocket.connect(baseURL: baseURL, token: token)

        streamTask = Task { [weak self] in
            for await message in stream {
                guard let self, !Task.isCancelled else { break }
                self.isConnected = self.webSocket.isConnected
                self.handleWSMessage(message)
            }
            self?.isConnected = false
        }
    }

    /// Disconnects from the WebSocket.
    func disconnect() {
        streamTask?.cancel()
        streamTask = nil
        webSocket.disconnect()
        isConnected = false
    }

    // MARK: - Sending

    /// Sends the current input text as a user message.
    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let userMessage = ChatMessage.user(text)
        messages.append(userMessage)
        inputText = ""

        if isConnected {
            awaitingSessionForSubmit = true
            webSocket.send(.submit(text: text))
        } else {
            // Fallback: create session via REST
            Task {
                await sendViaREST(text: text, userMessageId: userMessage.id)
            }
        }
    }

    /// Submits an approval decision for an inline approval card.
    func submitApproval(requestId: String, decision: ApprovalDecision) {
        if isConnected {
            webSocket.send(.approve(requestId: requestId, decision: decision))
        } else {
            Task {
                try? await client.submitApproval(id: requestId, decision: decision)
            }
        }

        // Mark the approval as resolved in the UI
        for i in messages.indices {
            if messages[i].approval?.id == requestId {
                messages[i].approval?.isResolved = true
                break
            }
        }
    }

    // MARK: - REST Fallback

    /// Creates a session via REST and monitors it with SSE when WebSocket
    /// is unavailable.
    private func sendViaREST(text: String, userMessageId: UUID) async {
        do {
            let request = CreateSessionRequest(text: text)
            let session = try await client.createSession(request)
            chatSessionIds.insert(session.id)

            // Add a thinking message
            let assistantMessage = ChatMessage.assistantThinking(sessionId: session.id)
            messages.append(assistantMessage)
            let assistantIndex = messages.count - 1

            // Poll for session completion via REST
            let sseClient = SSEClient(serverConfig: client.serverConfig)
            let eventStream = sseClient.connect(sessionId: session.id)

            for await event in eventStream {
                guard assistantIndex < messages.count else { break }
                handleSSEEvent(event, messageIndex: assistantIndex)

                // Stop polling once terminal
                if messages[assistantIndex].status == .completed ||
                   messages[assistantIndex].status == .failed {
                    sseClient.disconnect()
                    break
                }
            }
        } catch {
            // Update the user message to show it failed
            if let lastIndex = messages.indices.last, messages[lastIndex].role == .user {
                var failMessage = ChatMessage.system("Failed to send: \(error.localizedDescription)")
                failMessage.status = .failed
                messages.append(failMessage)
            }
        }
    }

    // MARK: - SSE Event Handling (REST fallback)

    private func handleSSEEvent(_ event: KarnEvil9Event, messageIndex: Int) {
        guard messageIndex < messages.count else { return }

        switch event {
        case .stepEvent(let journalEvent):
            handleStepEvent(journalEvent, messageIndex: messageIndex)
        case .plannerEvent(let journalEvent):
            handlePlannerEvent(journalEvent, messageIndex: messageIndex)
        case .approvalEvent(let journalEvent):
            handleApprovalEvent(journalEvent, messageIndex: messageIndex)
        case .sessionEvent(let journalEvent):
            handleSessionEvent(journalEvent, messageIndex: messageIndex)
        case .error(let message):
            messages[messageIndex].status = .failed
            messages[messageIndex].text = message
        case .unknown:
            break
        }
    }

    // MARK: - WebSocket Event Handling

    private func handleWSMessage(_ wsMessage: WSMessage) {
        switch wsMessage {
        case .sessionCreated(let sessionId, _):
            // Only create a thinking bubble if this session was initiated by the user
            guard awaitingSessionForSubmit else { break }
            guard findAssistantMessage(for: sessionId) == nil else { break }
            awaitingSessionForSubmit = false
            chatSessionIds.insert(sessionId)
            let assistantMessage = ChatMessage.assistantThinking(sessionId: sessionId)
            messages.append(assistantMessage)

        case .event(let sessionId, let event):
            guard chatSessionIds.contains(sessionId) else { return }
            guard let index = findAssistantMessage(for: sessionId) else { return }
            let karnevil9Event = KarnEvil9Event.categorize(event)
            switch karnevil9Event {
            case .stepEvent(let je):
                handleStepEvent(je, messageIndex: index)
            case .plannerEvent(let je):
                handlePlannerEvent(je, messageIndex: index)
            case .approvalEvent(let je):
                handleApprovalEvent(je, messageIndex: index)
            case .sessionEvent(let je):
                handleSessionEvent(je, messageIndex: index)
            case .error(let message):
                messages[index].status = .failed
                messages[index].text = message
            case .unknown:
                break
            }

        case .sessionCompleted(let sessionId, let event):
            guard chatSessionIds.contains(sessionId) else { return }
            guard let index = findAssistantMessage(for: sessionId) else { return }
            completeMessage(at: index, event: event)

        case .sessionFailed(let sessionId, let event):
            guard chatSessionIds.contains(sessionId) else { return }
            guard let index = findAssistantMessage(for: sessionId) else { return }
            messages[index].status = .failed
            messages[index].text = event.payloadSummary ?? "Session failed"

        case .sessionAborted(let sessionId, _):
            guard chatSessionIds.contains(sessionId) else { return }
            guard let index = findAssistantMessage(for: sessionId) else { return }
            messages[index].status = .failed
            messages[index].text = "Session was aborted"

        case .error(let message):
            messages.append(.system(message))

        case .pong, .submit, .abort, .approve, .ping:
            break
        }
    }

    // MARK: - Event Processors

    private func handleStepEvent(_ event: JournalEvent, messageIndex: Int) {
        guard messageIndex < messages.count else { return }

        let type = event.type
        let stepId = event.payload?["step_id"]?.stringValue ?? ""
        let tool = event.payload?["tool"]?.stringValue ?? "Unknown"

        if type == "step.started" {
            let title = event.payload?["title"]?.stringValue ?? tool
            let step = StepInfo(
                id: event.eventId,
                stepId: stepId,
                title: title,
                tool: tool,
                status: .running,
                output: nil
            )
            messages[messageIndex].steps.append(step)
        } else if type == "step.completed" || type == "step.succeeded" {
            // Match by step_id (preferred) or fall back to tool name
            let stepIndex = messages[messageIndex].steps.lastIndex(where: {
                (!stepId.isEmpty && $0.stepId == stepId) ||
                (stepId.isEmpty && $0.tool == tool && $0.status == .running)
            })
            if let stepIndex {
                messages[messageIndex].steps[stepIndex].status = .succeeded
                // Extract output text from nested output object
                messages[messageIndex].steps[stepIndex].output = extractStepOutput(from: event)
            }
        } else if type == "step.failed" {
            let stepIndex = messages[messageIndex].steps.lastIndex(where: {
                (!stepId.isEmpty && $0.stepId == stepId) ||
                (stepId.isEmpty && $0.tool == tool && $0.status == .running)
            })
            if let stepIndex {
                messages[messageIndex].steps[stepIndex].status = .failed
                messages[messageIndex].steps[stepIndex].output = event.payloadSummary
            }
        }
    }

    /// Extracts meaningful text from a step.succeeded event's output payload.
    /// Returns `nil` for structured/dictionary outputs that have no human-readable text,
    /// preventing "N fields" placeholders from leaking into the UI.
    private func extractStepOutput(from event: JournalEvent) -> String? {
        guard let payload = event.payload else { return nil }

        // Check for direct string output
        if let outputString = payload["output"]?.stringValue {
            return outputString
        }

        // Check for nested output object (e.g. respond tool: { output: { text: "..." } })
        if let outputDict = payload["output"]?.dictionaryValue {
            if let text = outputDict["text"]?.stringValue { return text }
            if let message = outputDict["message"]?.stringValue { return message }
            if let result = outputDict["result"]?.stringValue { return result }
            if let content = outputDict["content"]?.stringValue { return content }
            // Structured output with no readable text — return nil
            return nil
        }

        // Check top-level text fields
        if let text = payload["text"]?.stringValue { return text }
        if let result = payload["result"]?.stringValue { return result }
        if let message = payload["message"]?.stringValue { return message }

        // No readable text found — return nil rather than "N fields"
        return nil
    }

    private func handlePlannerEvent(_ event: JournalEvent, messageIndex: Int) {
        guard messageIndex < messages.count else { return }

        if event.type == "planner.plan_received" || event.type == "planner.plan_generated" {
            if let goal = event.payload?["goal"]?.stringValue {
                // Store as a thinking-phase step, not as the message text
                let step = StepInfo(
                    id: event.eventId,
                    stepId: "plan",
                    title: goal,
                    tool: "planner",
                    status: .succeeded,
                    output: nil
                )
                messages[messageIndex].steps.append(step)
            }
        }
    }

    private func handleApprovalEvent(_ event: JournalEvent, messageIndex: Int) {
        guard messageIndex < messages.count else { return }

        if event.type == "approval.requested" {
            let tool = event.payload?["tool"]?.stringValue ?? "Unknown"
            let description = event.payload?["description"]?.stringValue ?? ""
            let approvalId = event.payload?["approval_id"]?.stringValue ?? event.eventId

            let inline = InlineApproval(
                id: approvalId,
                sessionId: event.sessionId,
                tool: tool,
                description: description,
                input: event.payload,
                isResolved: false
            )
            messages[messageIndex].approval = inline
        } else if event.type == "approval.resolved" {
            messages[messageIndex].approval?.isResolved = true
        }
    }

    private func handleSessionEvent(_ event: JournalEvent, messageIndex: Int) {
        guard messageIndex < messages.count else { return }

        switch event.type {
        case "session.completed":
            completeMessage(at: messageIndex, event: event)
        case "session.failed":
            messages[messageIndex].status = .failed
            messages[messageIndex].text = event.payloadSummary ?? "Session failed"
        case "session.aborted":
            messages[messageIndex].status = .failed
            messages[messageIndex].text = "Session was aborted"
        default:
            break
        }
    }

    // MARK: - Helpers

    private func findAssistantMessage(for sessionId: String) -> Int? {
        messages.lastIndex(where: { $0.sessionId == sessionId && $0.role == .assistant })
    }

    private func completeMessage(at index: Int, event: JournalEvent) {
        guard index < messages.count else { return }

        messages[index].status = .completed

        // 1. Check for top-level response text
        if let text = event.payload?["text"]?.stringValue ??
                      event.payload?["result"]?.stringValue ??
                      event.payload?["message"]?.stringValue {
            messages[index].text = text
            return
        }

        // 2. Extract response from step_results (session.completed payload)
        if let responseText = extractResponseFromStepResults(event.payload) {
            messages[index].text = responseText
            return
        }

        // 3. Compile from step outputs already captured during streaming
        let outputs = messages[index].steps
            .filter { $0.status == .succeeded && $0.output != nil }
            .compactMap { $0.output }
        if !outputs.isEmpty {
            messages[index].text = outputs.joined(separator: "\n\n")
            return
        }

        // 4. Fallback
        if messages[index].text.isEmpty {
            messages[index].text = "Done."
        }
    }

    /// Extracts the response text from session.completed step_results payload.
    /// Looks for `respond` tool output first, then any step with a text field.
    private func extractResponseFromStepResults(_ payload: [String: AnyCodable]?) -> String? {
        guard let stepResults = payload?["step_results"]?.dictionaryValue else { return nil }

        // Search all step results for output text
        // Prefer the `respond` tool's output
        var fallbackText: String?

        for (_, stepResultValue) in stepResults {
            guard let stepResult = stepResultValue.dictionaryValue,
                  let output = stepResult["output"]?.dictionaryValue else { continue }

            if let text = output["text"]?.stringValue {
                // Check if this is from the respond tool (has delivered field)
                if output["delivered"] != nil {
                    return text  // Respond tool — use immediately
                }
                fallbackText = fallbackText ?? text
            }
        }

        return fallbackText
    }
}
