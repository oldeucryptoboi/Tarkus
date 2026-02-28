import Foundation

// MARK: - Response Types

/// Health check response from the KarnEvil9 API.
struct HealthResponse: Codable {
    let status: String
    let version: String?
}

/// Metadata about a tool registered in the KarnEvil9 server.
struct ToolInfo: Codable, Identifiable {
    let name: String
    let description: String?

    var id: String { name }
}

/// Metadata about a plugin registered in the KarnEvil9 server.
struct PluginInfo: Codable, Identifiable {
    let name: String
    let description: String?

    var id: String { name }
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

        guard let token = try KeychainService.getToken() else {
            throw APIError.unauthorized
        }

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
            // Models handle snake_case key mapping via explicit CodingKeys,
            // and date parsing via custom init(from:). No automatic strategies needed.
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

        guard let token = try KeychainService.getToken() else {
            throw APIError.unauthorized
        }

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

    /// Lists all sessions.
    func listSessions() async throws -> [Session] {
        try await request(.listSessions)
    }

    /// Creates a new Claude Code session.
    func createSession(_ request: CreateSessionRequest) async throws -> Session {
        try await self.request(.createSession(request))
    }

    /// Retrieves an existing session by identifier.
    func getSession(id: String) async throws -> Session {
        try await request(.getSession(id: id))
    }

    /// Retrieves the step journal for a session.
    func getSessionJournal(id: String) async throws -> [Step] {
        try await request(.getSessionJournal(id: id))
    }

    /// Requests that a running session be aborted.
    func abortSession(id: String) async throws {
        try await requestVoid(.abortSession(id: id))
    }

    /// Requests recovery of a failed or interrupted session.
    func recoverSession(id: String) async throws {
        try await requestVoid(.recoverSession(id: id))
    }

    /// Lists all pending approval requests.
    func listApprovals() async throws -> [Approval] {
        try await request(.listApprovals)
    }

    /// Submits a decision for a pending approval.
    func submitApproval(id: String, decision: ApprovalDecision) async throws {
        let response = ApprovalResponse(decision: decision)
        try await requestVoid(.submitApproval(id: id, response))
    }

    /// Lists all available tools on the server.
    func listTools() async throws -> [ToolInfo] {
        try await request(.listTools)
    }

    /// Lists all available plugins on the server.
    func listPlugins() async throws -> [PluginInfo] {
        try await request(.listPlugins)
    }
}
