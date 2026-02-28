import Foundation

// MARK: - PreviewData

/// Provides realistic mock data for use in SwiftUI previews and Xcode canvas
/// rendering. All values mirror the shapes returned by the KarnEvil9 API.
enum PreviewData {

    // MARK: - Usage Metrics

    static let usageMetrics = UsageMetrics(
        inputTokens: 15234,
        outputTokens: 3421,
        cacheReadTokens: 5000,
        cacheWriteTokens: 1200,
        totalCost: 0.0847
    )

    // MARK: - Sessions

    static let session = Session(
        id: "sess_001",
        task: "Implement user authentication with OAuth2",
        state: .running,
        plugin: "web-dev",
        createdAt: Date().addingTimeInterval(-3600),
        updatedAt: Date(),
        usage: usageMetrics,
        stepCount: 5
    )

    static let completedSession = Session(
        id: "sess_002",
        task: "Fix database migration script",
        state: .completed,
        plugin: nil,
        createdAt: Date().addingTimeInterval(-7200),
        updatedAt: Date().addingTimeInterval(-3600),
        usage: usageMetrics,
        stepCount: 12
    )

    static let sessions: [Session] = [session, completedSession]

    // MARK: - Tool Call & Result

    static let toolCall = ToolCall(
        id: "tc_001",
        tool: "Edit",
        input: [
            "file_path": AnyCodable("src/main.ts"),
            "old_string": AnyCodable("const x = 1"),
            "new_string": AnyCodable("const x = 2")
        ]
    )

    static let toolResult = ToolResult(
        id: "tr_001",
        output: "File edited successfully",
        error: nil,
        isError: false
    )

    // MARK: - Steps

    static let step = Step(
        id: "step_001",
        index: 0,
        state: .completed,
        toolCall: toolCall,
        toolResult: toolResult,
        assistantMessage: nil,
        startedAt: Date().addingTimeInterval(-60),
        completedAt: Date(),
        duration: 60
    )

    static let runningStep = Step(
        id: "step_002",
        index: 1,
        state: .running,
        toolCall: ToolCall(
            id: "tc_002",
            tool: "Read",
            input: [
                "file_path": AnyCodable("src/auth.ts")
            ]
        ),
        toolResult: nil,
        assistantMessage: nil,
        startedAt: Date().addingTimeInterval(-5),
        completedAt: nil,
        duration: nil
    )

    static let steps: [Step] = [step, runningStep]

    // MARK: - Permission & Approval

    static let permission = Permission(
        tool: "Bash",
        description: "Execute: rm -rf node_modules && npm install",
        input: [
            "command": AnyCodable("rm -rf node_modules && npm install")
        ]
    )

    static let approval = Approval(
        id: "appr_001",
        sessionId: "sess_001",
        permission: permission,
        status: "pending",
        createdAt: Date().addingTimeInterval(-30)
    )

    static let approvals: [Approval] = [approval]
}
