import Foundation

/// Hand-rolled Server-Sent Events client that connects to the KarnEvil9
/// session stream and yields parsed `KarnEvil9Event` values through an
/// `AsyncStream`.
@Observable
class SSEClient {

    // MARK: - Properties

    var isConnected: Bool = false
    var lastEventId: String?

    private var task: Task<Void, Never>?
    private let baseURL: URL
    private let token: String

    /// Maximum delay in seconds for exponential backoff reconnection.
    private let maxReconnectDelay: TimeInterval = 30

    // MARK: - Initialization

    init(baseURL: URL, token: String) {
        self.baseURL = baseURL
        self.token = token
    }

    /// Convenience initializer that extracts baseURL and token from a ServerConfig
    /// and Keychain.
    convenience init(serverConfig: ServerConfig) {
        let url = serverConfig.baseURL ?? URL(string: "http://localhost:3100")!
        let token = (try? KeychainService.getToken()) ?? ""
        self.init(baseURL: url, token: token)
    }

    // MARK: - Connection

    /// Opens an SSE connection to the given session's stream endpoint and
    /// returns an `AsyncStream` of parsed events. The stream automatically
    /// reconnects with exponential backoff on disconnection.
    func connect(sessionId: String) -> AsyncStream<KarnEvil9Event> {
        // Cancel any existing connection before starting a new one
        disconnect()

        return AsyncStream { continuation in
            task = Task { [weak self] in
                guard let self else {
                    continuation.finish()
                    return
                }

                var reconnectDelay: TimeInterval = 1

                while !Task.isCancelled {
                    do {
                        let url = self.baseURL
                            .appendingPathComponent("api/sessions/\(sessionId)/stream")

                        var request = URLRequest(url: url)
                        request.httpMethod = "GET"
                        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                        request.setValue("Bearer \(self.token)", forHTTPHeaderField: "Authorization")

                        if let lastId = self.lastEventId {
                            request.setValue(lastId, forHTTPHeaderField: "Last-Event-ID")
                        }

                        let (bytes, response) = try await URLSession.shared.bytes(for: request)

                        guard let httpResponse = response as? HTTPURLResponse,
                              (200...299).contains(httpResponse.statusCode) else {
                            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                            continuation.yield(
                                .error(message: "HTTP \(statusCode)")
                            )
                            break
                        }

                        await MainActor.run {
                            self.isConnected = true
                        }
                        reconnectDelay = 1 // Reset backoff on successful connection

                        // SSE line-by-line parsing state
                        var eventType: String?
                        var dataLines: [String] = []
                        var eventId: String?

                        for try await line in bytes.lines {
                            if Task.isCancelled { break }

                            if line.hasPrefix("event:") {
                                eventType = String(line.dropFirst(6)).trimmingCharacters(in: .whitespaces)
                            } else if line.hasPrefix("data:") {
                                let dataContent = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                                dataLines.append(dataContent)
                            } else if line.hasPrefix("id:") {
                                eventId = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                            } else if line.isEmpty {
                                // Empty line signals the end of an event
                                if let id = eventId {
                                    self.lastEventId = id
                                }

                                if !dataLines.isEmpty {
                                    let combinedData = dataLines.joined(separator: "\n")
                                    let event = KarnEvil9Event.parse(
                                        eventType: eventType,
                                        data: combinedData
                                    )
                                    continuation.yield(event)
                                }

                                // Reset parsing state for the next event
                                eventType = nil
                                dataLines = []
                                eventId = nil
                            }
                            // Lines starting with ":" are comments — ignored
                        }

                    } catch is CancellationError {
                        break
                    } catch {
                        // Connection failed or dropped
                    }

                    // Mark disconnected
                    await MainActor.run {
                        self.isConnected = false
                    }

                    // Exit if cancelled during reconnect
                    if Task.isCancelled { break }

                    // Exponential backoff before reconnecting
                    try? await Task.sleep(nanoseconds: UInt64(reconnectDelay * 1_000_000_000))
                    reconnectDelay = min(reconnectDelay * 2, self.maxReconnectDelay)
                }

                await MainActor.run {
                    self.isConnected = false
                }
                continuation.finish()
            }

            continuation.onTermination = { [weak self] _ in
                self?.task?.cancel()
            }
        }
    }

    // MARK: - Disconnection

    /// Cancels the active SSE connection and marks the client as disconnected.
    func disconnect() {
        task?.cancel()
        task = nil
        isConnected = false
    }
}
