import Foundation

// MARK: - ChatMessage

/// A single message in the EDDIE chat conversation.
struct ChatMessage: Identifiable {

    let id: UUID
    let role: Role
    var text: String
    let timestamp: Date
    var sessionId: String?
    var status: Status
    var steps: [StepInfo]
    var approval: InlineApproval?

    // MARK: - Role

    enum Role {
        case user
        case assistant
        case system
    }

    // MARK: - Status

    enum Status {
        case sending
        case thinking
        case completed
        case failed
    }

    // MARK: - Initializers

    /// Creates a user message.
    static func user(_ text: String) -> ChatMessage {
        ChatMessage(
            id: UUID(),
            role: .user,
            text: text,
            timestamp: Date(),
            sessionId: nil,
            status: .sending,
            steps: [],
            approval: nil
        )
    }

    /// Creates an assistant message in thinking state.
    static func assistantThinking(sessionId: String) -> ChatMessage {
        ChatMessage(
            id: UUID(),
            role: .assistant,
            text: "",
            timestamp: Date(),
            sessionId: sessionId,
            status: .thinking,
            steps: [],
            approval: nil
        )
    }

    /// Creates a system message (e.g. connection status).
    static func system(_ text: String) -> ChatMessage {
        ChatMessage(
            id: UUID(),
            role: .system,
            text: text,
            timestamp: Date(),
            sessionId: nil,
            status: .completed,
            steps: [],
            approval: nil
        )
    }
}

// MARK: - StepInfo

/// Represents a single tool execution step within an EDDIE response.
struct StepInfo: Identifiable {
    let id: String
    let stepId: String
    let title: String
    let tool: String
    var status: StepStatus
    var output: String?

    enum StepStatus: String {
        case running
        case succeeded
        case failed
    }
}

// MARK: - InlineApproval

/// An approval request displayed inline within a chat message.
struct InlineApproval: Identifiable {
    let id: String
    let sessionId: String
    let tool: String
    let description: String
    let input: [String: AnyCodable]?
    var isResolved: Bool
}
