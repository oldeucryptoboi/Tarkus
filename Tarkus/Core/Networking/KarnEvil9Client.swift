import Foundation

// MARK: - Response Wrappers

/// Health check response from the KarnEvil9 API.
struct HealthResponse: Codable {
    let status: String
    let version: String?
}

/// Wrapper for the sessions list endpoint: `{ "sessions": [...] }`.
struct SessionsResponse: Codable {
    let sessions: [Session]
}

/// Wrapper for the approvals list endpoint: `{ "pending": [...] }`.
struct ApprovalsResponse: Codable {
    let pending: [Approval]
}

/// Wrapper for the journal endpoint: `{ "events": [...] }`.
struct JournalResponse: Codable {
    let events: [JournalEvent]
}

/// Wrapper for the tools list endpoint: `{ "tools": [...] }`.
struct ToolsResponse: Codable {
    let tools: [ToolInfo]
}

/// Metadata about a tool registered in the KarnEvil9 server.
struct ToolInfo: Codable, Identifiable {
    let name: String
    let description: String?
    let version: String?

    var id: String { name }

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case version
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        version = try container.decodeIfPresent(String.self, forKey: .version)
    }

    init(name: String, description: String? = nil, version: String? = nil) {
        self.name = name
        self.description = description
        self.version = version
    }
}

// MARK: - KarnEvil9Client

/// Async/await REST client for communicating with the KarnEvil9 API.
@Observable
class KarnEvil9Client {

    // MARK: - Properties

    var serverConfig: ServerConfig
    private let urlSession: URLSession

    // MARK: - Initialization

    init(serverConfig: ServerConfig) {
        self.serverConfig = serverConfig

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        self.urlSession = URLSession(configuration: configuration)
    }

    // MARK: - Internal Request Helper

    /// Sends a request for the given endpoint and decodes the response into
    /// the specified `Decodable` type.
    private func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard let baseURL = serverConfig.baseURL else {
            throw APIError.invalidURL
        }

        let token = try? KeychainService.getToken()

        let urlRequest = endpoint.urlRequest(baseURL: baseURL, token: token)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: urlRequest)
        } catch {
            throw APIError.from(networkError: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw APIError.unauthorized
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.from(decodingError: error)
        }
    }

    /// Sends a request for the given endpoint that returns no meaningful body.
    private func requestVoid(_ endpoint: APIEndpoint) async throws {
        guard let baseURL = serverConfig.baseURL else {
            throw APIError.invalidURL
        }

        let token = try? KeychainService.getToken()

        let urlRequest = endpoint.urlRequest(baseURL: baseURL, token: token)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: urlRequest)
        } catch {
            throw APIError.from(networkError: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.unknown
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message)
        }
    }

    // MARK: - Public API

    /// Checks the health of the KarnEvil9 server.
    func healthCheck() async throws -> HealthResponse {
        try await request(.health)
    }

    /// Lists all sessions (unwraps `{ "sessions": [...] }`).
    func listSessions() async throws -> [Session] {
        let response: SessionsResponse = try await request(.listSessions)
        return response.sessions
    }

    /// Creates a new Claude Code session. Converts the API's
    /// `CreateSessionResponse` into a `Session` for the caller.
    func createSession(_ createRequest: CreateSessionRequest) async throws -> Session {
        let response: CreateSessionResponse = try await request(.createSession(createRequest))
        return Session(
            id: response.sessionId,
            task: response.task?.text ?? createRequest.text,
            state: SessionState(rawValue: response.status) ?? .unknown,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Retrieves an existing session by identifier.
    func getSession(id: String) async throws -> Session {
        try await request(.getSession(id: id))
    }

    /// Retrieves the journal events for a session (unwraps `{ "events": [...] }`).
    func getSessionJournal(id: String) async throws -> [JournalEvent] {
        let response: JournalResponse = try await request(.getSessionJournal(id: id))
        return response.events
    }

    /// Requests that a running session be aborted.
    func abortSession(id: String) async throws {
        try await requestVoid(.abortSession(id: id))
    }

    /// Requests recovery of a failed or interrupted session.
    func recoverSession(id: String) async throws {
        try await requestVoid(.recoverSession(id: id))
    }

    /// Lists all pending approval requests (unwraps `{ "pending": [...] }`).
    func listApprovals() async throws -> [Approval] {
        let response: ApprovalsResponse = try await request(.listApprovals)
        return response.pending
    }

    /// Submits a decision for a pending approval.
    func submitApproval(id: String, decision: ApprovalDecision) async throws {
        let response = ApprovalResponse(decision: decision)
        try await requestVoid(.submitApproval(id: id, response))
    }

    /// Lists all available tools on the server (unwraps `{ "tools": [...] }`).
    func listTools() async throws -> [ToolInfo] {
        let response: ToolsResponse = try await request(.listTools)
        return response.tools
    }
}
