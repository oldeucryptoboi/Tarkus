import Foundation

// MARK: - PreviewData

/// Provides realistic mock data for use in SwiftUI previews and Xcode canvas
/// rendering. All values mirror the shapes returned by the KarnEvil9 API.
enum PreviewData {

    // MARK: - Sessions

    static let session = Session(
        id: "sess_001",
        task: "Implement user authentication with OAuth2",
        state: .running,
        mode: "auto",
        createdAt: Date().addingTimeInterval(-3600),
        updatedAt: Date()
    )

    static let completedSession = Session(
        id: "sess_002",
        task: "Fix database migration script",
        state: .completed,
        createdAt: Date().addingTimeInterval(-7200),
        updatedAt: Date().addingTimeInterval(-3600)
    )

    static let sessions: [Session] = [session, completedSession]

    // MARK: - Journal Events

    static let sessionCreatedEvent = JournalEvent(
        eventId: "evt_001",
        timestamp: Date().addingTimeInterval(-60),
        sessionId: "sess_001",
        type: "session.created",
        payload: ["task": AnyCodable("Implement user authentication with OAuth2")],
        seq: 1
    )

    static let stepStartedEvent = JournalEvent(
        eventId: "evt_002",
        timestamp: Date().addingTimeInterval(-50),
        sessionId: "sess_001",
        type: "step.started",
        payload: ["tool": AnyCodable("Read")],
        seq: 2
    )

    static let stepCompletedEvent = JournalEvent(
        eventId: "evt_003",
        timestamp: Date().addingTimeInterval(-40),
        sessionId: "sess_001",
        type: "step.completed",
        payload: ["tool": AnyCodable("Read")],
        seq: 3
    )

    static let plannerEvent = JournalEvent(
        eventId: "evt_004",
        timestamp: Date().addingTimeInterval(-30),
        sessionId: "sess_001",
        type: "planner.plan_generated",
        payload: ["plan": AnyCodable("1. Read auth config\n2. Implement OAuth flow")],
        seq: 4
    )

    static let approvalEvent = JournalEvent(
        eventId: "evt_005",
        timestamp: Date().addingTimeInterval(-20),
        sessionId: "sess_001",
        type: "approval.requested",
        payload: ["tool": AnyCodable("Bash"), "command": AnyCodable("npm install oauth2-client")],
        seq: 5
    )

    static let events: [JournalEvent] = [
        sessionCreatedEvent,
        stepStartedEvent,
        stepCompletedEvent,
        plannerEvent,
        approvalEvent
    ]

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

    // MARK: - Usage Metrics

    static let usageMetrics = UsageMetrics(
        inputTokens: 15234,
        outputTokens: 3421,
        cacheReadTokens: 5000,
        cacheWriteTokens: 1200,
        totalCost: 0.0847
    )
}
