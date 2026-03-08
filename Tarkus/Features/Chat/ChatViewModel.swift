import Foundation
import os.log

private let chatLog = Logger(subsystem: "com.artivisual.Tarkus", category: "Chat")

// MARK: - ChatViewModel

/// Manages chat state and WebSocket event routing for the EDDIE chat interface.
@Observable
@MainActor
class ChatViewModel {

    // MARK: - Properties

    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isConnected: Bool { webSocket.isConnected }

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
    /// Idempotent — does nothing if already connected or a stream task is active.
    func connect() {
        guard streamTask == nil else {
            NSLog("[Chat] connect() — streamTask already exists, skipping")
            return
        }
        guard let baseURL = client.serverConfig.baseURL else {
            NSLog("[Chat] connect() — no baseURL")
            return
        }
        NSLog("[Chat] connect() — connecting to %@", baseURL.absoluteString)
        let token = try? KeychainService.getToken()

        let stream = webSocket.connect(baseURL: baseURL, token: token)

        streamTask = Task { [weak self] in
            NSLog("[Chat] streamTask started — awaiting messages")
            for await message in stream {
                guard let self, !Task.isCancelled else {
                    NSLog("[Chat] streamTask — self nil or cancelled")
                    break
                }
                self.handleWSMessage(message)
            }
            NSLog("[Chat] streamTask ended")
            guard let self else { return }
            self.streamTask = nil
        }
    }

    /// Disconnects from the WebSocket.
    func disconnect() {
        streamTask?.cancel()
        streamTask = nil
        webSocket.disconnect()
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
            chatLog.notice("Sending via WebSocket: \(String(text.prefix(80)), privacy: .public)")
            awaitingSessionForSubmit = true
            webSocket.send(.submit(text: text))
        } else {
            chatLog.warning("Sending via REST fallback (WS not connected): \(String(text.prefix(80)), privacy: .public)")
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
        NSLog("[Chat] handleWSMessage: %@", String(String(describing: wsMessage).prefix(300)))
        switch wsMessage {
        case .sessionCreated(let sessionId, _):
            // Only create a thinking bubble if this session was initiated by the user
            guard awaitingSessionForSubmit else {
                chatLog.notice("Ignoring session.created \(sessionId, privacy: .public) — not awaiting submit")
                break
            }
            guard findAssistantMessage(for: sessionId) == nil else {
                chatLog.notice("Ignoring session.created \(sessionId, privacy: .public) — assistant message already exists")
                break
            }
            awaitingSessionForSubmit = false
            chatSessionIds.insert(sessionId)
            let assistantMessage = ChatMessage.assistantThinking(sessionId: sessionId)
            messages.append(assistantMessage)
            chatLog.notice("Session created \(sessionId, privacy: .public) — thinking bubble added (tracked: \(self.chatSessionIds.count) sessions)")

        case .event(let sessionId, let event):
            guard chatSessionIds.contains(sessionId) else {
                chatLog.debug("Dropping event \(event.type, privacy: .public) for untracked session \(sessionId, privacy: .public)")
                return
            }
            guard let index = findAssistantMessage(for: sessionId) else {
                chatLog.warning("Dropping event \(event.type, privacy: .public) — no assistant message for session \(sessionId, privacy: .public)")
                return
            }
            let karnevil9Event = KarnEvil9Event.categorize(event)
            NSLog("[Chat] event type=%@ categorized=%@", event.type, String(String(describing: karnevil9Event).prefix(200)))
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
                chatLog.error("Event error for session \(sessionId, privacy: .public): \(message, privacy: .public)")
                messages[index].status = .failed
                messages[index].text = message
            case .unknown:
                chatLog.debug("Unknown event type=\(event.type, privacy: .public) for session \(sessionId, privacy: .public)")
                break
            }

        case .sessionCompleted(let sessionId, let event):
            guard chatSessionIds.contains(sessionId) else {
                chatLog.warning("Dropping session.completed for untracked session \(sessionId, privacy: .public)")
                return
            }
            guard let index = findAssistantMessage(for: sessionId) else {
                chatLog.warning("Dropping session.completed — no assistant message for session \(sessionId, privacy: .public)")
                return
            }
            chatLog.notice("Session completed \(sessionId, privacy: .public) — completing message at index \(index)")
            completeMessage(at: index, event: event)

        case .sessionFailed(let sessionId, let event):
            guard chatSessionIds.contains(sessionId) else {
                chatLog.warning("Dropping session.failed for untracked session \(sessionId, privacy: .public)")
                return
            }
            guard let index = findAssistantMessage(for: sessionId) else {
                chatLog.warning("Dropping session.failed — no assistant message for session \(sessionId, privacy: .public)")
                return
            }
            chatLog.error("Session failed \(sessionId, privacy: .public): \(event.payloadSummary ?? "?", privacy: .public)")
            messages[index].status = .failed
            messages[index].text = event.payloadSummary ?? "Session failed"

        case .sessionAborted(let sessionId, _):
            guard chatSessionIds.contains(sessionId) else { return }
            guard let index = findAssistantMessage(for: sessionId) else { return }
            chatLog.notice("Session aborted \(sessionId, privacy: .public)")
            messages[index].status = .failed
            messages[index].text = "Session was aborted"

        case .error(let message):
            chatLog.error("WS error message: \(message, privacy: .public)")
            messages.append(.system(message))

        case .pong, .submit, .abort, .approve, .ping:
            break
        }
    }

    // MARK: - Event Processors

    private func handleStepEvent(_ event: JournalEvent, messageIndex: Int) {
        guard messageIndex < messages.count else {
            chatLog.error("handleStepEvent — messageIndex \(messageIndex) out of bounds (count=\(self.messages.count))")
            return
        }

        let type = event.type
        let stepId = event.payload?["step_id"]?.stringValue ?? ""
        let tool = event.payload?["tool"]?.stringValue ?? "Unknown"

        NSLog("[Chat] handleStepEvent: type=%@ tool=%@ stepId=%@ msgStatus=%@", type, tool, stepId, String(describing: messages[messageIndex].status))

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
                let output = extractStepOutput(from: event)
                messages[messageIndex].steps[stepIndex].output = output

                // When the respond tool delivers text, transition to streaming
                // so the user sees the response with a typing dot while the session finishes.
                let effectiveTool = messages[messageIndex].steps[stepIndex].tool
                if effectiveTool == "respond", let text = output, !text.isEmpty,
                   messages[messageIndex].status == .thinking {
                    chatLog.notice("Respond tool delivered \(text.count) chars — transitioning to streaming")
                    messages[messageIndex].text = text
                    messages[messageIndex].status = .streaming
                    // Extract mood from respond output
                    if let outputDict = event.payload?["output"]?.dictionaryValue,
                       let moodStr = outputDict["mood"]?.stringValue {
                        messages[messageIndex].mood = GERTYMood(rawValue: moodStr)
                    }
                } else if effectiveTool == "respond" {
                    chatLog.warning("Respond tool completed but NO text extracted (output=\(output == nil ? "nil" : "empty", privacy: .public), status=\(String(describing: self.messages[messageIndex].status), privacy: .public))")
                }
            } else {
                chatLog.warning("Step \(type, privacy: .public) completed but no matching running step (stepId=\(stepId, privacy: .public), tool=\(tool, privacy: .public))")
            }
        } else if type == "step.failed" {
            let stepIndex = messages[messageIndex].steps.lastIndex(where: {
                (!stepId.isEmpty && $0.stepId == stepId) ||
                (stepId.isEmpty && $0.tool == tool && $0.status == .running)
            })
            if let stepIndex {
                messages[messageIndex].steps[stepIndex].status = .failed
                messages[messageIndex].steps[stepIndex].output = event.payloadSummary
                chatLog.notice("Step failed: tool=\(tool, privacy: .public) stepId=\(stepId, privacy: .public)")
            } else {
                chatLog.warning("Step failed but no matching running step (stepId=\(stepId, privacy: .public), tool=\(tool, privacy: .public))")
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

        NSLog("[Chat] handleSessionEvent: type=%@ session=%@ msgIndex=%d", event.type, event.sessionId, messageIndex)

        switch event.type {
        case "session.completed":
            completeMessage(at: messageIndex, event: event)
        case "session.failed":
            chatLog.error("Session failed (via wrapper): \(event.payloadSummary ?? "?", privacy: .public)")
            messages[messageIndex].status = .failed
            messages[messageIndex].text = event.payloadSummary ?? "Session failed"
        case "session.aborted":
            chatLog.notice("Session aborted (via wrapper)")
            messages[messageIndex].status = .failed
            messages[messageIndex].text = "Session was aborted"
        default:
            break
        }
    }

    // MARK: - Public Computed

    /// The mood from the most recent assistant message that has one, or `nil`.
    var lastMood: GERTYMood? {
        messages.last(where: { $0.role == .assistant && $0.mood != nil })?.mood
    }

    // MARK: - Helpers

    private func findAssistantMessage(for sessionId: String) -> Int? {
        messages.lastIndex(where: { $0.sessionId == sessionId && $0.role == .assistant })
    }

    private func completeMessage(at index: Int, event: JournalEvent) {
        guard index < messages.count else {
            NSLog("[Chat] completeMessage — index %d out of bounds (count=%d)", index, messages.count)
            return
        }

        let previousStatus = String(describing: messages[index].status)
        NSLog("[Chat] completeMessage at index=%d, eventType=%@ previousStatus=%@", index, event.type, previousStatus)
        messages[index].status = .completed

        // 1. Check for top-level response text
        if let text = event.payload?["text"]?.stringValue ??
                      event.payload?["result"]?.stringValue ??
                      event.payload?["message"]?.stringValue {
            messages[index].text = text
            chatLog.notice("completeMessage — top-level text (\(text.count) chars), was \(previousStatus, privacy: .public)")
            return
        }

        // 2. Extract response from step_results (session.completed payload)
        let (responseText, responseMood) = extractResponseFromStepResults(event.payload)
        if let responseText {
            messages[index].text = responseText
            if messages[index].mood == nil, let responseMood {
                messages[index].mood = responseMood
            }
            chatLog.notice("completeMessage — step_results text (\(responseText.count) chars), was \(previousStatus, privacy: .public)")
            return
        }

        // 3. Compile from step outputs already captured during streaming
        let outputs = messages[index].steps
            .filter { $0.status == .succeeded && $0.output != nil }
            .compactMap { $0.output }
        if !outputs.isEmpty {
            messages[index].text = outputs.joined(separator: "\n\n")
            chatLog.notice("completeMessage — compiled from \(outputs.count) step outputs, was \(previousStatus, privacy: .public)")
            return
        }

        // 4. Fallback
        if messages[index].text.isEmpty {
            chatLog.warning("completeMessage — no text found, falling back to 'Done.' (was \(previousStatus, privacy: .public), payload keys=\(event.payload?.keys.joined(separator: ",") ?? "nil", privacy: .public))")
            messages[index].text = "Done."
        } else {
            chatLog.notice("completeMessage — keeping existing text (\(self.messages[index].text.count) chars), was \(previousStatus, privacy: .public)")
        }
    }

    /// Extracts the response text and mood from session.completed step_results payload.
    /// Looks for `respond` tool output first, then any step with a text field.
    private func extractResponseFromStepResults(_ payload: [String: AnyCodable]?) -> (String?, GERTYMood?) {
        guard let stepResults = payload?["step_results"]?.dictionaryValue else { return (nil, nil) }

        // Search all step results for output text
        // Prefer the `respond` tool's output
        var fallbackText: String?

        for (_, stepResultValue) in stepResults {
            guard let stepResult = stepResultValue.dictionaryValue,
                  let output = stepResult["output"]?.dictionaryValue else { continue }

            if let text = output["text"]?.stringValue {
                // Check if this is from the respond tool (has delivered field)
                if output["delivered"] != nil {
                    let mood = output["mood"]?.stringValue.flatMap { GERTYMood(rawValue: $0) }
                    return (text, mood)  // Respond tool — use immediately
                }
                fallbackText = fallbackText ?? text
            }
        }

        return (fallbackText, nil)
    }
}
