import Foundation

// MARK: - Step State

/// The execution state of an individual step within a session.
enum StepState: String, Codable, Equatable {
    case pending
    case running
    case completed
    case failed
}

// MARK: - Tool Call

/// A tool invocation requested by the assistant during a session step.
struct ToolCall: Codable, Identifiable, Equatable {
    let id: String
    let tool: String
    let input: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case id
        case tool
        case input
    }
}

// MARK: - Tool Result

/// The result of executing a tool call.
struct ToolResult: Codable, Identifiable, Equatable {
    let id: String
    let output: String?
    let error: String?
    let isError: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case output
        case error
        case isError = "is_error"
    }
}

// MARK: - Step

/// A single step within a KarnEvil9 session, representing one unit of work
/// that may include a tool call, tool result, and/or assistant message.
struct Step: Codable, Identifiable, Equatable {
    let id: String
    let index: Int
    let state: StepState
    let toolCall: ToolCall?
    let toolResult: ToolResult?
    let assistantMessage: String?
    let startedAt: Date?
    let completedAt: Date?
    let duration: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case id
        case index
        case state
        case toolCall = "tool_call"
        case toolResult = "tool_result"
        case assistantMessage = "assistant_message"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case duration
    }

    // MARK: - Custom Decoding (ISO8601 dates)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        index = try container.decode(Int.self, forKey: .index)
        state = try container.decode(StepState.self, forKey: .state)
        toolCall = try container.decodeIfPresent(ToolCall.self, forKey: .toolCall)
        toolResult = try container.decodeIfPresent(ToolResult.self, forKey: .toolResult)
        assistantMessage = try container.decodeIfPresent(String.self, forKey: .assistantMessage)
        duration = try container.decodeIfPresent(TimeInterval.self, forKey: .duration)

        if let startedAtString = try container.decodeIfPresent(String.self, forKey: .startedAt) {
            startedAt = try Self.parseISO8601Date(startedAtString, codingPath: container.codingPath + [CodingKeys.startedAt])
        } else {
            startedAt = nil
        }

        if let completedAtString = try container.decodeIfPresent(String.self, forKey: .completedAt) {
            completedAt = try Self.parseISO8601Date(completedAtString, codingPath: container.codingPath + [CodingKeys.completedAt])
        } else {
            completedAt = nil
        }
    }

    // MARK: - Custom Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(index, forKey: .index)
        try container.encode(state, forKey: .state)
        try container.encodeIfPresent(toolCall, forKey: .toolCall)
        try container.encodeIfPresent(toolResult, forKey: .toolResult)
        try container.encodeIfPresent(assistantMessage, forKey: .assistantMessage)
        try container.encodeIfPresent(duration, forKey: .duration)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let startedAt = startedAt {
            try container.encode(formatter.string(from: startedAt), forKey: .startedAt)
        }
        if let completedAt = completedAt {
            try container.encode(formatter.string(from: completedAt), forKey: .completedAt)
        }
    }

    // MARK: - Memberwise Initializer

    init(
        id: String,
        index: Int,
        state: StepState,
        toolCall: ToolCall? = nil,
        toolResult: ToolResult? = nil,
        assistantMessage: String? = nil,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.index = index
        self.state = state
        self.toolCall = toolCall
        self.toolResult = toolResult
        self.assistantMessage = assistantMessage
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.duration = duration
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
