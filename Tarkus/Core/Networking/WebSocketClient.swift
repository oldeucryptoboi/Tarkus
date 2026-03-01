import Foundation

// MARK: - WebSocket Message Types

/// Messages exchanged over the WebSocket connection to the KarnEvil9 API.
enum WSMessage {

    // MARK: - Outbound

    /// Submit a new task for EDDIE to process.
    case submit(text: String)

    /// Abort an active session.
    case abort(sessionId: String)

    /// Respond to an approval request.
    case approve(requestId: String, decision: ApprovalDecision)

    /// Client keepalive ping.
    case ping

    // MARK: - Inbound

    /// A new session was created for the submitted task.
    case sessionCreated(sessionId: String, event: JournalEvent)

    /// A journal event for an active session.
    case event(sessionId: String, event: JournalEvent)

    /// The session completed successfully.
    case sessionCompleted(sessionId: String, event: JournalEvent)

    /// The session failed.
    case sessionFailed(sessionId: String, event: JournalEvent)

    /// The session was aborted.
    case sessionAborted(sessionId: String, event: JournalEvent)

    /// Server error message.
    case error(message: String)

    /// Server keepalive pong.
    case pong
}

// MARK: - WebSocketClient

/// Native WebSocket client using `URLSessionWebSocketTask` for bidirectional
/// real-time communication with the KarnEvil9 API.
@Observable
class WebSocketClient {

    // MARK: - Properties

    var isConnected: Bool = false

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var continuation: AsyncStream<WSMessage>.Continuation?
    private var receiveTask: Task<Void, Never>?
    private var pingTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?

    private var baseURL: URL?
    private var token: String?

    /// Maximum delay in seconds for exponential backoff reconnection.
    private let maxReconnectDelay: TimeInterval = 30

    /// Ping interval in seconds.
    private let pingInterval: TimeInterval = 30

    /// Whether the client should attempt to reconnect on disconnection.
    private var shouldReconnect: Bool = false

    // MARK: - Connection

    /// Connects to the WebSocket endpoint and returns an `AsyncStream` of
    /// inbound messages. Automatically reconnects with exponential backoff.
    func connect(baseURL: URL, token: String?) -> AsyncStream<WSMessage> {
        disconnect()

        self.baseURL = baseURL
        self.token = token
        self.shouldReconnect = true

        return AsyncStream { continuation in
            self.continuation = continuation

            continuation.onTermination = { [weak self] _ in
                self?.disconnect()
            }

            self.performConnect()
        }
    }

    /// Disconnects the WebSocket and stops reconnection attempts.
    func disconnect() {
        shouldReconnect = false
        receiveTask?.cancel()
        receiveTask = nil
        pingTask?.cancel()
        pingTask = nil
        reconnectTask?.cancel()
        reconnectTask = nil
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        continuation?.finish()
        continuation = nil

        Task { @MainActor in
            self.isConnected = false
        }
    }

    /// Sends an outbound message over the WebSocket connection.
    func send(_ message: WSMessage) {
        guard let webSocketTask, webSocketTask.state == .running else { return }

        let json: [String: Any]
        switch message {
        case .submit(let text):
            json = ["type": "submit", "text": text]
        case .abort(let sessionId):
            json = ["type": "abort", "session_id": sessionId]
        case .approve(let requestId, let decision):
            json = ["type": "approve", "request_id": requestId, "decision": decision.rawValue]
        case .ping:
            json = ["type": "ping"]
        default:
            return // Inbound-only messages cannot be sent
        }

        guard let data = try? JSONSerialization.data(withJSONObject: json) else { return }

        webSocketTask.send(.string(String(data: data, encoding: .utf8) ?? "")) { error in
            if error != nil {
                // Send failed — connection may have dropped
            }
        }
    }

    // MARK: - Private

    private func performConnect() {
        guard let baseURL, shouldReconnect else { return }

        // Build ws:// or wss:// URL from the http:// base URL
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.scheme = baseURL.scheme == "https" ? "wss" : "ws"
        components?.path = "/api/ws"

        // KarnEvil9 authenticates WebSocket via ?token= query param
        if let token, !token.isEmpty {
            components?.queryItems = [URLQueryItem(name: "token", value: token)]
        }

        guard let wsURL = components?.url else {
            continuation?.yield(.error(message: "Invalid WebSocket URL"))
            return
        }

        let request = URLRequest(url: wsURL)

        let urlSession = URLSession(configuration: .default)
        self.session = urlSession
        let task = urlSession.webSocketTask(with: request)
        self.webSocketTask = task
        task.resume()

        startReceiving()
        startPinging()

        // Send an initial ping to trigger a pong, which confirms connectivity
        send(.ping)
    }

    private func startReceiving() {
        receiveTask = Task { [weak self] in
            guard let self else { return }

            var reconnectDelay: TimeInterval = 1

            while !Task.isCancelled {
                guard let webSocketTask = self.webSocketTask else { break }

                do {
                    let message = try await webSocketTask.receive()
                    reconnectDelay = 1 // Reset backoff on successful receive

                    await MainActor.run {
                        self.isConnected = true
                    }

                    switch message {
                    case .string(let text):
                        let wsMessage = self.parseInbound(text)
                        self.continuation?.yield(wsMessage)

                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            let wsMessage = self.parseInbound(text)
                            self.continuation?.yield(wsMessage)
                        }

                    @unknown default:
                        break
                    }
                } catch {
                    // Connection dropped
                    await MainActor.run {
                        self.isConnected = false
                    }

                    guard self.shouldReconnect, !Task.isCancelled else { break }

                    // Exponential backoff reconnect
                    try? await Task.sleep(nanoseconds: UInt64(reconnectDelay * 1_000_000_000))
                    reconnectDelay = min(reconnectDelay * 2, self.maxReconnectDelay)

                    self.performConnect()
                    return // New receiveTask started by performConnect
                }
            }
        }
    }

    private func startPinging() {
        pingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64((self?.pingInterval ?? 30) * 1_000_000_000))
                self?.webSocketTask?.sendPing { error in
                    if error != nil {
                        // Ping failed — connection may have dropped
                    }
                }
            }
        }
    }

    // MARK: - Parsing

    /// Parses an inbound JSON string into a `WSMessage`.
    private func parseInbound(_ text: String) -> WSMessage {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return .error(message: "Unable to parse WebSocket message")
        }

        // Handle pong
        if type == "pong" {
            return .pong
        }

        // Handle server error
        if type == "error" {
            let message = json["message"] as? String ?? "Unknown error"
            return .error(message: message)
        }

        let sessionId = json["session_id"] as? String ?? ""

        // Try to parse the inner "event" object as a JournalEvent.
        // The server wraps events as { type: "event", session_id, event: { type: "session.failed", ... } }.
        let event: JournalEvent
        let innerEventType: String?

        if let eventData = json["event"] as? [String: Any] {
            innerEventType = eventData["type"] as? String
            if let eventJson = try? JSONSerialization.data(withJSONObject: eventData),
               let parsed = try? JSONDecoder().decode(JournalEvent.self, from: eventJson) {
                event = parsed
            } else {
                // Inner event exists but failed full decode — use its type
                event = JournalEvent(
                    eventId: (eventData["event_id"] as? String) ?? UUID().uuidString,
                    timestamp: Date(),
                    sessionId: (eventData["session_id"] as? String) ?? sessionId,
                    type: innerEventType ?? type
                )
            }
        } else if let parsed = try? JSONDecoder().decode(JournalEvent.self, from: data) {
            event = parsed
            innerEventType = nil
        } else {
            innerEventType = nil
            event = JournalEvent(
                eventId: UUID().uuidString,
                timestamp: Date(),
                sessionId: sessionId,
                type: type
            )
        }

        // Use the inner event type when the outer type is just "event".
        let effectiveType = (type == "event") ? (innerEventType ?? event.type) : type

        switch effectiveType {
        case "session.created":
            return .sessionCreated(sessionId: sessionId, event: event)
        case "session.completed":
            return .sessionCompleted(sessionId: sessionId, event: event)
        case "session.failed":
            return .sessionFailed(sessionId: sessionId, event: event)
        case "session.aborted":
            return .sessionAborted(sessionId: sessionId, event: event)
        default:
            return .event(sessionId: sessionId, event: event)
        }
    }
}
