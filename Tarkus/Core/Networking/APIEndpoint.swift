import Foundation

/// Defines all KarnEvil9 API routes, computing the path, HTTP method, and
/// optional request body for each endpoint.
enum APIEndpoint {

    // MARK: - Health

    case health

    // MARK: - Sessions

    case listSessions
    case createSession(CreateSessionRequest)
    case getSession(id: String)
    case streamSession(id: String)
    case getSessionJournal(id: String)
    case abortSession(id: String)
    case recoverSession(id: String)

    // MARK: - Approvals

    case listApprovals
    case submitApproval(id: String, ApprovalResponse)

    // MARK: - Tools & Plugins

    case listTools
    case listPlugins

    // MARK: - Route Properties

    var path: String {
        switch self {
        case .health:
            return "/api/health"
        case .listSessions:
            return "/api/sessions"
        case .createSession:
            return "/api/sessions"
        case .getSession(let id):
            return "/api/sessions/\(id)"
        case .streamSession(let id):
            return "/api/sessions/\(id)/stream"
        case .getSessionJournal(let id):
            return "/api/sessions/\(id)/journal"
        case .abortSession(let id):
            return "/api/sessions/\(id)/abort"
        case .recoverSession(let id):
            return "/api/sessions/\(id)/recover"
        case .listApprovals:
            return "/api/approvals"
        case .submitApproval(let id, _):
            return "/api/approvals/\(id)"
        case .listTools:
            return "/api/tools"
        case .listPlugins:
            return "/api/plugins"
        }
    }

    var method: String {
        switch self {
        case .health,
             .listSessions,
             .getSession,
             .streamSession,
             .getSessionJournal,
             .listApprovals,
             .listTools,
             .listPlugins:
            return "GET"
        case .createSession,
             .abortSession,
             .recoverSession,
             .submitApproval:
            return "POST"
        }
    }

    var body: Data? {
        switch self {
        case .createSession(let request):
            return try? JSONEncoder().encode(request)
        case .submitApproval(_, let response):
            return try? JSONEncoder().encode(response)
        default:
            return nil
        }
    }

    // MARK: - URLRequest Builder

    /// Constructs a fully configured `URLRequest` from the endpoint, base URL,
    /// and authentication token.
    func urlRequest(baseURL: URL, token: String) -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)

        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = body
        }

        // SSE endpoints require a different Accept header
        if case .streamSession = self {
            request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        } else {
            request.setValue("application/json", forHTTPHeaderField: "Accept")
        }

        return request
    }
}
