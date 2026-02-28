import XCTest
@testable import Tarkus

// MARK: - SSEClientTests

/// Tests for the SSE event parsing logic in `KarnEvil9Event.parse(eventType:data:decoder:)`.
/// Each test constructs a realistic JSON payload matching what the KarnEvil9 SSE stream
/// would emit, then verifies the parsed event contains the expected data.
final class SSEClientTests: XCTestCase {

    // MARK: - Helpers

    /// A plain decoder — the models handle their own ISO8601 date parsing.
    private let decoder = JSONDecoder()

    // MARK: - Session Events

    func testParseSessionStartedEvent() throws {
        let json = """
        {
            "id": "sess_start_001",
            "task": "Build a REST API",
            "state": "running",
            "plugin": "backend",
            "created_at": "2025-06-15T10:00:00.000Z",
            "updated_at": "2025-06-15T10:00:00.000Z",
            "step_count": 0
        }
        """

        let event = try KarnEvil9Event.parse(
            eventType: "session_started",
            data: json,
            decoder: decoder
        )

        if case .sessionStarted(let session) = event {
            XCTAssertEqual(session.id, "sess_start_001")
            XCTAssertEqual(session.task, "Build a REST API")
            XCTAssertEqual(session.state, .running)
            XCTAssertEqual(session.plugin, "backend")
        } else {
            XCTFail("Expected .sessionStarted, got \(event)")
        }
    }

    // MARK: - Step Events

    func testParseStepCompletedEvent() throws {
        let json = """
        {
            "id": "step_comp_001",
            "index": 2,
            "state": "completed",
            "tool_call": {
                "id": "tc_comp_001",
                "tool": "Write",
                "input": {
                    "file_path": "src/index.ts",
                    "content": "console.log('hello')"
                }
            },
            "tool_result": {
                "id": "tr_comp_001",
                "output": "File written successfully",
                "error": null,
                "is_error": false
            },
            "started_at": "2025-06-15T10:01:00.000Z",
            "completed_at": "2025-06-15T10:01:03.500Z",
            "duration": 3.5
        }
        """

        let event = try KarnEvil9Event.parse(
            eventType: "step_completed",
            data: json,
            decoder: decoder
        )

        if case .stepCompleted(let step) = event {
            XCTAssertEqual(step.id, "step_comp_001")
            XCTAssertEqual(step.index, 2)
            XCTAssertEqual(step.state, .completed)
            XCTAssertEqual(step.toolCall?.tool, "Write")
            XCTAssertEqual(step.toolResult?.output, "File written successfully")
            XCTAssertEqual(step.toolResult?.isError, false)
            XCTAssertEqual(step.duration ?? 0, 3.5, accuracy: 0.01)
        } else {
            XCTFail("Expected .stepCompleted, got \(event)")
        }
    }

    // MARK: - Permission Events

    func testParsePermissionRequestedEvent() throws {
        let json = """
        {
            "id": "appr_perm_001",
            "session_id": "sess_start_001",
            "permission": {
                "tool": "Bash",
                "description": "Execute: docker compose up -d",
                "input": {
                    "command": "docker compose up -d"
                }
            },
            "status": "pending",
            "created_at": "2025-06-15T10:02:00.000Z"
        }
        """

        let event = try KarnEvil9Event.parse(
            eventType: "permission_requested",
            data: json,
            decoder: decoder
        )

        if case .permissionRequested(let approval) = event {
            XCTAssertEqual(approval.id, "appr_perm_001")
            XCTAssertEqual(approval.sessionId, "sess_start_001")
            XCTAssertEqual(approval.permission.tool, "Bash")
            XCTAssertEqual(approval.permission.description, "Execute: docker compose up -d")
            XCTAssertEqual(approval.status, "pending")
        } else {
            XCTFail("Expected .permissionRequested, got \(event)")
        }
    }

    // MARK: - Heartbeat Event

    func testParseHeartbeatEvent() throws {
        // Heartbeat events typically carry an empty JSON object or minimal data.
        let json = "{}"

        let event = try KarnEvil9Event.parse(
            eventType: "heartbeat",
            data: json,
            decoder: decoder
        )

        if case .heartbeat = event {
            // Success — heartbeat parsed correctly.
        } else {
            XCTFail("Expected .heartbeat, got \(event)")
        }
    }

    // MARK: - Usage Updated Event

    func testParseUsageUpdatedEvent() throws {
        let json = """
        {
            "input_tokens": 18500,
            "output_tokens": 4200,
            "cache_read_tokens": 6000,
            "cache_write_tokens": 1500,
            "total_cost": 0.0950
        }
        """

        let event = try KarnEvil9Event.parse(
            eventType: "usage_updated",
            data: json,
            decoder: decoder
        )

        if case .usageUpdated(let metrics) = event {
            XCTAssertEqual(metrics.inputTokens, 18500)
            XCTAssertEqual(metrics.outputTokens, 4200)
            XCTAssertEqual(metrics.cacheReadTokens, 6000)
            XCTAssertEqual(metrics.cacheWriteTokens, 1500)
            XCTAssertEqual(metrics.totalCost, 0.095, accuracy: 0.0001)
            XCTAssertEqual(metrics.totalTokens, 22700)
        } else {
            XCTFail("Expected .usageUpdated, got \(event)")
        }
    }

    // MARK: - Error Event

    func testParseErrorEvent() throws {
        let json = """
        {
            "message": "Session timed out after 300 seconds of inactivity"
        }
        """

        let event = try KarnEvil9Event.parse(
            eventType: "error",
            data: json,
            decoder: decoder
        )

        if case .error(let message) = event {
            XCTAssertEqual(message, "Session timed out after 300 seconds of inactivity")
        } else {
            XCTFail("Expected .error, got \(event)")
        }
    }

    // MARK: - Unrecognized Event Type

    func testParseUnrecognizedEventThrows() {
        let json = "{}"

        XCTAssertThrowsError(
            try KarnEvil9Event.parse(
                eventType: "unknown_event_type",
                data: json,
                decoder: decoder
            )
        ) { error in
            if case APIError.sseError(let detail) = error {
                XCTAssertTrue(detail.contains("Unrecognized SSE event type"))
            } else {
                XCTFail("Expected APIError.sseError, got \(error)")
            }
        }
    }

    // MARK: - Malformed Data

    func testParseMalformedDataThrows() {
        let badJson = "this is not json"

        XCTAssertThrowsError(
            try KarnEvil9Event.parse(
                eventType: "session_started",
                data: badJson,
                decoder: decoder
            )
        )
    }

    // MARK: - Additional Session Events

    func testParseSessionCompletedEvent() throws {
        let json = """
        {
            "id": "sess_done_001",
            "task": "Refactor authentication module",
            "state": "completed",
            "created_at": "2025-06-15T09:00:00.000Z",
            "updated_at": "2025-06-15T10:30:00.000Z",
            "usage": {
                "input_tokens": 45000,
                "output_tokens": 12000,
                "cache_read_tokens": 15000,
                "cache_write_tokens": 3000,
                "total_cost": 0.285
            },
            "step_count": 25
        }
        """

        let event = try KarnEvil9Event.parse(
            eventType: "session_completed",
            data: json,
            decoder: decoder
        )

        if case .sessionCompleted(let session) = event {
            XCTAssertEqual(session.id, "sess_done_001")
            XCTAssertEqual(session.state, .completed)
            XCTAssertEqual(session.stepCount, 25)
            XCTAssertEqual(session.usage?.totalCost ?? 0, 0.285, accuracy: 0.001)
        } else {
            XCTFail("Expected .sessionCompleted, got \(event)")
        }
    }

    func testParseStepStartedEvent() throws {
        let json = """
        {
            "id": "step_start_001",
            "index": 0,
            "state": "running",
            "tool_call": {
                "id": "tc_start_001",
                "tool": "Read",
                "input": {
                    "file_path": "package.json"
                }
            },
            "started_at": "2025-06-15T10:00:01.000Z"
        }
        """

        let event = try KarnEvil9Event.parse(
            eventType: "step_started",
            data: json,
            decoder: decoder
        )

        if case .stepStarted(let step) = event {
            XCTAssertEqual(step.id, "step_start_001")
            XCTAssertEqual(step.state, .running)
            XCTAssertEqual(step.toolCall?.tool, "Read")
        } else {
            XCTFail("Expected .stepStarted, got \(event)")
        }
    }
}
