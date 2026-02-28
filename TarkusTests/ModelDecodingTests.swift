import XCTest
@testable import Tarkus

// MARK: - ModelDecodingTests

/// Verifies that all core model types decode correctly from realistic JSON
/// payloads matching the KarnEvil9 API response format (snake_case keys,
/// ISO8601 dates with fractional seconds).
final class ModelDecodingTests: XCTestCase {

    // MARK: - Helpers

    /// A plain `JSONDecoder` — models handle their own date decoding via
    /// custom `init(from:)` implementations rather than relying on a
    /// decoder-level date strategy.
    private let decoder = JSONDecoder()

    // MARK: - Session Decoding

    func testSessionDecoding() throws {
        let json = """
        {
            "id": "sess_abc123",
            "task": "Implement user authentication",
            "state": "running",
            "plugin": "web-dev",
            "created_at": "2025-06-15T10:30:00.000Z",
            "updated_at": "2025-06-15T11:00:00.000Z",
            "usage": {
                "input_tokens": 12000,
                "output_tokens": 3500,
                "cache_read_tokens": 4000,
                "cache_write_tokens": 800,
                "total_cost": 0.072
            },
            "step_count": 7
        }
        """.data(using: .utf8)!

        let session = try decoder.decode(Session.self, from: json)

        XCTAssertEqual(session.id, "sess_abc123")
        XCTAssertEqual(session.task, "Implement user authentication")
        XCTAssertEqual(session.state, .running)
        XCTAssertEqual(session.plugin, "web-dev")
        XCTAssertEqual(session.stepCount, 7)
        XCTAssertNotNil(session.usage)
        XCTAssertEqual(session.usage?.inputTokens, 12000)
        XCTAssertEqual(session.usage?.outputTokens, 3500)
        XCTAssertEqual(session.usage?.totalCost, 0.072)
    }

    func testSessionDecodingMinimalFields() throws {
        let json = """
        {
            "id": "sess_minimal",
            "task": "Quick fix",
            "state": "idle",
            "created_at": "2025-06-15T10:30:00Z",
            "updated_at": "2025-06-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let session = try decoder.decode(Session.self, from: json)

        XCTAssertEqual(session.id, "sess_minimal")
        XCTAssertEqual(session.state, .idle)
        XCTAssertNil(session.plugin)
        XCTAssertNil(session.usage)
        XCTAssertNil(session.stepCount)
    }

    func testSessionStateTerminal() {
        XCTAssertTrue(SessionState.completed.isTerminal)
        XCTAssertTrue(SessionState.failed.isTerminal)
        XCTAssertTrue(SessionState.aborted.isTerminal)
        XCTAssertFalse(SessionState.running.isTerminal)
        XCTAssertFalse(SessionState.idle.isTerminal)
    }

    func testSessionStateActive() {
        XCTAssertTrue(SessionState.running.isActive)
        XCTAssertTrue(SessionState.paused.isActive)
        XCTAssertTrue(SessionState.waitingForApproval.isActive)
        XCTAssertFalse(SessionState.completed.isActive)
        XCTAssertFalse(SessionState.idle.isActive)
    }

    // MARK: - Step Decoding

    func testStepDecoding() throws {
        let json = """
        {
            "id": "step_001",
            "index": 3,
            "state": "completed",
            "tool_call": {
                "id": "tc_001",
                "tool": "Edit",
                "input": {
                    "file_path": "src/main.ts",
                    "old_string": "const x = 1",
                    "new_string": "const x = 2"
                }
            },
            "tool_result": {
                "id": "tr_001",
                "output": "File edited successfully",
                "error": null,
                "is_error": false
            },
            "assistant_message": null,
            "started_at": "2025-06-15T10:31:00.500Z",
            "completed_at": "2025-06-15T10:31:05.200Z",
            "duration": 4.7
        }
        """.data(using: .utf8)!

        let step = try decoder.decode(Step.self, from: json)

        XCTAssertEqual(step.id, "step_001")
        XCTAssertEqual(step.index, 3)
        XCTAssertEqual(step.state, .completed)
        XCTAssertNotNil(step.toolCall)
        XCTAssertEqual(step.toolCall?.tool, "Edit")
        XCTAssertEqual(step.toolCall?.input["file_path"]?.stringValue, "src/main.ts")
        XCTAssertNotNil(step.toolResult)
        XCTAssertEqual(step.toolResult?.output, "File edited successfully")
        XCTAssertEqual(step.toolResult?.isError, false)
        XCTAssertNil(step.assistantMessage)
        XCTAssertNotNil(step.startedAt)
        XCTAssertNotNil(step.completedAt)
        XCTAssertEqual(step.duration ?? 0, 4.7, accuracy: 0.01)
    }

    func testStepDecodingRunningState() throws {
        let json = """
        {
            "id": "step_running",
            "index": 0,
            "state": "running",
            "tool_call": {
                "id": "tc_run",
                "tool": "Bash",
                "input": {
                    "command": "npm test"
                }
            },
            "started_at": "2025-06-15T10:31:00.000Z"
        }
        """.data(using: .utf8)!

        let step = try decoder.decode(Step.self, from: json)

        XCTAssertEqual(step.state, .running)
        XCTAssertNil(step.toolResult)
        XCTAssertNil(step.completedAt)
        XCTAssertNil(step.duration)
    }

    // MARK: - Approval Decoding

    func testApprovalDecoding() throws {
        let json = """
        {
            "id": "appr_xyz789",
            "session_id": "sess_abc123",
            "permission": {
                "tool": "Bash",
                "description": "Execute: rm -rf node_modules && npm install",
                "input": {
                    "command": "rm -rf node_modules && npm install"
                }
            },
            "status": "pending",
            "created_at": "2025-06-15T10:32:00.000Z"
        }
        """.data(using: .utf8)!

        let approval = try decoder.decode(Approval.self, from: json)

        XCTAssertEqual(approval.id, "appr_xyz789")
        XCTAssertEqual(approval.sessionId, "sess_abc123")
        XCTAssertEqual(approval.status, "pending")
        XCTAssertEqual(approval.permission.tool, "Bash")
        XCTAssertEqual(approval.permission.description, "Execute: rm -rf node_modules && npm install")
        XCTAssertNotNil(approval.permission.input)
        XCTAssertEqual(approval.permission.input?["command"]?.stringValue, "rm -rf node_modules && npm install")
    }

    func testApprovalDecisionRoundTrip() throws {
        let response = ApprovalResponse(decision: .allowOnce)
        let data = try JSONEncoder().encode(response)
        let decoded = try decoder.decode(ApprovalResponse.self, from: data)

        XCTAssertEqual(decoded.decision, .allowOnce)
    }

    // MARK: - UsageMetrics Decoding

    func testUsageMetricsDecoding() throws {
        let json = """
        {
            "input_tokens": 25000,
            "output_tokens": 8500,
            "cache_read_tokens": 10000,
            "cache_write_tokens": 2500,
            "total_cost": 0.1523
        }
        """.data(using: .utf8)!

        let metrics = try decoder.decode(UsageMetrics.self, from: json)

        XCTAssertEqual(metrics.inputTokens, 25000)
        XCTAssertEqual(metrics.outputTokens, 8500)
        XCTAssertEqual(metrics.cacheReadTokens, 10000)
        XCTAssertEqual(metrics.cacheWriteTokens, 2500)
        XCTAssertEqual(metrics.totalCost, 0.1523, accuracy: 0.0001)
        XCTAssertEqual(metrics.totalTokens, 33500)
    }

    func testUsageMetricsZero() {
        let zero = UsageMetrics.zero
        XCTAssertEqual(zero.inputTokens, 0)
        XCTAssertEqual(zero.outputTokens, 0)
        XCTAssertEqual(zero.totalTokens, 0)
        XCTAssertEqual(zero.totalCost, 0.0)
    }

    // MARK: - AnyCodable

    func testAnyCodableString() throws {
        let json = """
        {"value": "hello"}
        """.data(using: .utf8)!

        let container = try decoder.decode([String: AnyCodable].self, from: json)
        XCTAssertEqual(container["value"]?.stringValue, "hello")
    }

    func testAnyCodableInt() throws {
        let json = """
        {"value": 42}
        """.data(using: .utf8)!

        let container = try decoder.decode([String: AnyCodable].self, from: json)
        XCTAssertEqual(container["value"]?.intValue, 42)
    }

    func testAnyCodableBool() throws {
        let json = """
        {"value": true}
        """.data(using: .utf8)!

        let container = try decoder.decode([String: AnyCodable].self, from: json)
        XCTAssertEqual(container["value"]?.boolValue, true)
    }

    func testAnyCodableDouble() throws {
        let json = """
        {"value": 3.14}
        """.data(using: .utf8)!

        let container = try decoder.decode([String: AnyCodable].self, from: json)
        XCTAssertEqual(container["value"]?.doubleValue ?? 0, 3.14, accuracy: 0.001)
    }

    func testAnyCodableNull() throws {
        let json = """
        {"value": null}
        """.data(using: .utf8)!

        let container = try decoder.decode([String: AnyCodable].self, from: json)
        XCTAssertTrue(container["value"]?.isNil ?? false)
    }

    func testAnyCodableRoundTrip() throws {
        let original: [String: AnyCodable] = [
            "name": AnyCodable("test"),
            "count": AnyCodable(42),
            "enabled": AnyCodable(true)
        ]

        let data = try JSONEncoder().encode(original)
        let decoded = try decoder.decode([String: AnyCodable].self, from: data)

        XCTAssertEqual(decoded["name"]?.stringValue, "test")
        XCTAssertEqual(decoded["count"]?.intValue, 42)
        XCTAssertEqual(decoded["enabled"]?.boolValue, true)
    }

    func testAnyCodableEquality() {
        XCTAssertEqual(AnyCodable("a"), AnyCodable("a"))
        XCTAssertNotEqual(AnyCodable("a"), AnyCodable("b"))
        XCTAssertEqual(AnyCodable(42), AnyCodable(42))
        XCTAssertNotEqual(AnyCodable(42), AnyCodable(43))
        XCTAssertEqual(AnyCodable(nil), AnyCodable(nil))
        XCTAssertNotEqual(AnyCodable(nil), AnyCodable(0))
    }

    // MARK: - Session Round-Trip Encoding

    func testSessionRoundTrip() throws {
        let original = Session(
            id: "sess_round",
            task: "Round trip test",
            state: .paused,
            plugin: "test-plugin",
            createdAt: Date(),
            updatedAt: Date(),
            usage: UsageMetrics(
                inputTokens: 100,
                outputTokens: 50,
                cacheReadTokens: 20,
                cacheWriteTokens: 10,
                totalCost: 0.005
            ),
            stepCount: 3
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.task, original.task)
        XCTAssertEqual(decoded.state, original.state)
        XCTAssertEqual(decoded.plugin, original.plugin)
        XCTAssertEqual(decoded.stepCount, original.stepCount)
        XCTAssertEqual(decoded.usage?.inputTokens, original.usage?.inputTokens)
    }
}
