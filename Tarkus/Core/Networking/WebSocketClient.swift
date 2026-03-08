import Foundation
import os.log

private let wsLog = Logger(subsystem: "com.artivisual.Tarkus", category: "WebSocket")

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

    /// If no pong received within this many seconds, mark as disconnected.
    private let pongTimeout: TimeInterval = 45

    /// Timestamp of the last pong received from the server.
    private var lastPongReceived: Date = .distantPast

    /// Whether the client should attempt to reconnect on disconnection.
    private var shouldReconnect: Bool = false

    // MARK: - Connection

    /// Connects to the WebSocket endpoint and returns an `AsyncStream` of
    /// inbound messages. Automatically reconnects with exponential backoff.
    func connect(baseURL: URL, token: String?) -> AsyncStream<WSMessage> {
        NSLog("[WS] connect() called — baseURL=%@", baseURL.absoluteString)
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
        wsLog.notice("Disconnecting (shouldReconnect was \(self.shouldReconnect))")
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
        guard let webSocketTask, webSocketTask.state == .running else {
            wsLog.warning("Send failed — task not running (state=\(self.webSocketTask?.state.rawValue ?? -1))")
            return
        }

        let json: [String: Any]
        switch message {
        case .submit(let text):
            json = ["type": "submit", "text": text]
            wsLog.notice("Sending submit: \(String(text.prefix(80)), privacy: .public)")
        case .abort(let sessionId):
            json = ["type": "abort", "session_id": sessionId]
            wsLog.notice("Sending abort: session=\(sessionId, privacy: .public)")
        case .approve(let requestId, let decision):
            json = ["type": "approve", "request_id": requestId, "decision": decision.rawValue]
            wsLog.notice("Sending approve: request=\(requestId, privacy: .public) decision=\(decision.rawValue, privacy: .public)")
        case .ping:
            json = ["type": "ping"]
        default:
            return // Inbound-only messages cannot be sent
        }

        guard let data = try? JSONSerialization.data(withJSONObject: json) else {
            wsLog.error("Send failed — JSON serialization error")
            return
        }

        webSocketTask.send(.string(String(data: data, encoding: .utf8) ?? "")) { error in
            if let error {
                wsLog.error("Send failed — \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    // MARK: - Private

    private func performConnect() {
        guard let baseURL, shouldReconnect else {
            wsLog.warning("performConnect skipped (baseURL=\(self.baseURL?.absoluteString ?? "nil", privacy: .public), shouldReconnect=\(self.shouldReconnect))")
            return
        }

        // Build ws:// or wss:// URL from the http:// base URL
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.scheme = baseURL.scheme == "https" ? "wss" : "ws"
        components?.path = "/api/ws"

        // KarnEvil9 authenticates WebSocket via ?token= query param
        if let token, !token.isEmpty {
            components?.queryItems = [URLQueryItem(name: "token", value: token)]
        }

        guard let wsURL = components?.url else {
            wsLog.error("performConnect failed — invalid URL")
            continuation?.yield(.error(message: "Invalid WebSocket URL"))
            return
        }

        wsLog.notice("Connecting to \(wsURL.host ?? "?", privacy: .public)/\(wsURL.path, privacy: .public)")

        let request = URLRequest(url: wsURL)

        let urlSession = URLSession(configuration: .default)
        self.session = urlSession
        let task = urlSession.webSocketTask(with: request)
        self.webSocketTask = task
        self.lastPongReceived = Date()
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
                guard let webSocketTask = self.webSocketTask else {
                    wsLog.warning("Receive loop exiting — webSocketTask is nil")
                    break
                }

                do {
                    let message = try await webSocketTask.receive()
                    reconnectDelay = 1 // Reset backoff on successful receive

                    await MainActor.run {
                        self.isConnected = true
                    }

                    switch message {
                    case .string(let text):
                        NSLog("[WS] Received raw: %@", String(text.prefix(200)))
                        let wsMessage = self.parseInbound(text)
                        self.continuation?.yield(wsMessage)

                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            let wsMessage = self.parseInbound(text)
                            self.continuation?.yield(wsMessage)
                        } else {
                            wsLog.warning("Received binary data that could not be decoded as UTF-8 (\(data.count) bytes)")
                        }

                    @unknown default:
                        wsLog.warning("Received unknown message type")
                        break
                    }
                } catch {
                    NSLog("[WS] Connection dropped — %@", error.localizedDescription)

                    await MainActor.run {
                        self.isConnected = false
                    }

                    guard self.shouldReconnect, !Task.isCancelled else {
                        wsLog.notice("Not reconnecting (shouldReconnect=\(self.shouldReconnect), cancelled=\(Task.isCancelled))")
                        break
                    }

                    wsLog.notice("Reconnecting in \(Int(reconnectDelay))s")
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
                guard let self, !Task.isCancelled else { break }

                // Send app-level ping
                self.send(.ping)

                // Check if we've received a pong recently
                let elapsed = Date().timeIntervalSince(self.lastPongReceived)
                if elapsed > self.pongTimeout {
                    wsLog.warning("No pong received in \(Int(elapsed))s — marking disconnected")
                    await MainActor.run {
                        self.isConnected = false
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
            wsLog.error("Parse failed — invalid JSON or missing type: \(String(text.prefix(200)), privacy: .public)")
            return .error(message: "Unable to parse WebSocket message")
        }

        // Handle pong — update last-seen timestamp
        if type == "pong" {
            self.lastPongReceived = Date()
            return .pong
        }

        // Handle server error
        if type == "error" {
            let message = json["message"] as? String ?? "Unknown error"
            wsLog.error("Server error: \(message, privacy: .public)")
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
                wsLog.error("JournalEvent decode failed for inner event type=\(innerEventType ?? "?", privacy: .public) session=\(sessionId, privacy: .public) — payload lost")
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
            wsLog.error("JournalEvent decode failed for outer type=\(type, privacy: .public) session=\(sessionId, privacy: .public)")
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

        NSLog("[WS] Parsed: type=%@ effective=%@ session=%@ hasPayload=%d", type, effectiveType, sessionId, event.payload != nil ? 1 : 0)

        // session.created needs special handling (creates thinking bubble),
        // everything else routes through .event → KarnEvil9Event.categorize()
        if effectiveType == "session.created" {
            return .sessionCreated(sessionId: sessionId, event: event)
        }
        return .event(sessionId: sessionId, event: event)
    }
}
