import Foundation

// MARK: - Session State

/// The lifecycle state of a KarnEvil9 session.
enum SessionState: String, Codable, CaseIterable, Equatable {
    case idle
    case running
    case paused
    case waitingForApproval = "waiting_for_approval"
    case completed
    case failed
    case aborted

    /// Whether the session is in a terminal state.
    var isTerminal: Bool {
        switch self {
        case .completed, .failed, .aborted:
            return true
        default:
            return false
        }
    }

    /// Whether the session is actively processing.
    var isActive: Bool {
        switch self {
        case .running, .paused, .waitingForApproval:
            return true
        default:
            return false
        }
    }
}

// MARK: - Create Session Request

/// Request body for creating a new session via the KarnEvil9 API.
struct CreateSessionRequest: Codable, Equatable {
    let task: String
    let plugin: String?
    let allowedTools: [String]?

    enum CodingKeys: String, CodingKey {
        case task
        case plugin
        case allowedTools = "allowed_tools"
    }
}

// MARK: - Session

/// A session as returned by the KarnEvil9 API.
struct Session: Codable, Identifiable, Equatable {
    let id: String
    let task: String
    let state: SessionState
    let plugin: String?
    let createdAt: Date
    let updatedAt: Date
    let usage: UsageMetrics?
    let stepCount: Int?

    enum CodingKeys: String, CodingKey {
        case id
        case task
        case state
        case plugin
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case usage
        case stepCount = "step_count"
    }

    // MARK: - Custom Decoding (ISO8601 dates)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        task = try container.decode(String.self, forKey: .task)
        state = try container.decode(SessionState.self, forKey: .state)
        plugin = try container.decodeIfPresent(String.self, forKey: .plugin)
        usage = try container.decodeIfPresent(UsageMetrics.self, forKey: .usage)
        stepCount = try container.decodeIfPresent(Int.self, forKey: .stepCount)

        // Support both fractional-seconds and standard ISO8601
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)

        createdAt = try Self.parseISO8601Date(createdAtString, codingPath: container.codingPath + [CodingKeys.createdAt])
        updatedAt = try Self.parseISO8601Date(updatedAtString, codingPath: container.codingPath + [CodingKeys.updatedAt])
    }

    // MARK: - Custom Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(task, forKey: .task)
        try container.encode(state, forKey: .state)
        try container.encodeIfPresent(plugin, forKey: .plugin)
        try container.encodeIfPresent(usage, forKey: .usage)
        try container.encodeIfPresent(stepCount, forKey: .stepCount)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
        try container.encode(formatter.string(from: updatedAt), forKey: .updatedAt)
    }

    // MARK: - Memberwise Initializer

    init(
        id: String,
        task: String,
        state: SessionState,
        plugin: String? = nil,
        createdAt: Date,
        updatedAt: Date,
        usage: UsageMetrics? = nil,
        stepCount: Int? = nil
    ) {
        self.id = id
        self.task = task
        self.state = state
        self.plugin = plugin
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.usage = usage
        self.stepCount = stepCount
    }

    // MARK: - Date Parsing Helper

    private static func parseISO8601Date(_ string: String, codingPath: [CodingKey]) throws -> Date {
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatterWithFractional.date(from: string) {
            return date
        }

        let formatterStandard = ISO8601DateFormatter()
        formatterStandard.formatOptions = [.withInternetDateTime]

        if let date = formatterStandard.date(from: string) {
            return date
        }

        throw DecodingError.dataCorrupted(
            DecodingError.Context(
                codingPath: codingPath,
                debugDescription: "Unable to parse ISO8601 date: \(string)"
            )
        )
    }
}
