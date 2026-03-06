import Foundation

// MARK: - Session State

/// The lifecycle state of a KarnEvil9 session.
enum SessionState: String, Codable, CaseIterable, Equatable {
    case planning
    case running
    case completed
    case failed
    case aborted
    case unknown
    case live
    case paused

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
        case .running, .planning, .live, .paused:
            return true
        default:
            return false
        }
    }

    /// Decode with a fallback to `.unknown` for unrecognized statuses.
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = SessionState(rawValue: rawValue) ?? .unknown
    }
}

// MARK: - Create Session Request

/// Request body for creating a new session via the KarnEvil9 API.
struct CreateSessionRequest: Codable, Equatable {
    let text: String
}

// MARK: - Create Session Response

/// Response from the KarnEvil9 API when creating a new session.
/// The API returns `{ "session_id": "...", "status": "...", "task": { "text": "..." } }`.
struct CreateSessionResponse: Codable {
    let sessionId: String
    let status: String
    let task: TaskObject?

    struct TaskObject: Codable {
        let text: String
    }

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case status
        case task
    }
}

// MARK: - Session

/// A session as returned by the KarnEvil9 API.
struct Session: Codable, Identifiable, Equatable {
    let id: String
    let task: String
    var state: SessionState
    let mode: String?
    let createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case id
        case task
        case taskText = "task_text"
        case status
        case state
        case mode
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Custom Decoding

    /// Handles both list and detail API shapes:
    /// - List: `{ "session_id": "...", "task_text": "...", "status": "..." }`
    /// - Detail: `{ "session_id": "...", "task": { "text": "..." }, "status": "..." }`
    /// Also handles the memberwise-encoded shape (with `id`, `task` as string, `state`).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode id: prefer "session_id", fall back to "id"
        if let sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId) {
            id = sessionId
        } else {
            id = try container.decode(String.self, forKey: .id)
        }

        // Decode task: try "task_text" (list), then "task" as object (detail), then "task" as string (memberwise)
        if let taskText = try container.decodeIfPresent(String.self, forKey: .taskText) {
            task = taskText
        } else if let taskObject = try? container.decode(CreateSessionResponse.TaskObject.self, forKey: .task) {
            task = taskObject.text
        } else if let taskString = try container.decodeIfPresent(String.self, forKey: .task) {
            task = taskString
        } else {
            task = ""
        }

        // Decode state: prefer "status", fall back to "state"
        if let status = try container.decodeIfPresent(SessionState.self, forKey: .status) {
            state = status
        } else {
            state = try container.decode(SessionState.self, forKey: .state)
        }

        mode = try container.decodeIfPresent(String.self, forKey: .mode)

        // Support both fractional-seconds and standard ISO8601
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = try Self.parseISO8601Date(createdAtString, codingPath: container.codingPath + [CodingKeys.createdAt])
        } else {
            createdAt = Date()
        }

        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = try Self.parseISO8601Date(updatedAtString, codingPath: container.codingPath + [CodingKeys.updatedAt])
        } else {
            updatedAt = Date()
        }
    }

    // MARK: - Custom Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(task, forKey: .task)
        try container.encode(state, forKey: .state)
        try container.encodeIfPresent(mode, forKey: .mode)

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
        mode: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.task = task
        self.state = state
        self.mode = mode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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
