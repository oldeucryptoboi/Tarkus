import XCTest
@testable import Tarkus

// MARK: - ModelDecodingTests

/// Verifies that all core model types decode correctly from realistic JSON
/// payloads matching the actual KarnEvil9 API response format.
final class ModelDecodingTests: XCTestCase {

    // MARK: - Helpers

    private let decoder = JSONDecoder()

    // MARK: - Session Decoding (List Shape)

    func testSessionDecodingFromListShape() throws {
        let json = """
        {
            "session_id": "sess_abc123",
            "task_text": "Implement user authentication",
            "status": "running",
            "mode": "auto",
            "created_at": "2025-06-15T10:30:00.000Z",
            "updated_at": "2025-06-15T11:00:00.000Z"
        }
        """.data(using: .utf8)!

        let session = try decoder.decode(Session.self, from: json)

        XCTAssertEqual(session.id, "sess_abc123")
        XCTAssertEqual(session.task, "Implement user authentication")
        XCTAssertEqual(session.state, .running)
        XCTAssertEqual(session.mode, "auto")
    }

    // MARK: - Session Decoding (Detail Shape)

    func testSessionDecodingFromDetailShape() throws {
        let json = """
        {
            "session_id": "sess_detail_001",
            "task": { "text": "Refactor auth module" },
            "status": "planning",
            "created_at": "2025-06-15T10:30:00.000Z",
            "updated_at": "2025-06-15T11:00:00.000Z"
        }
        """.data(using: .utf8)!

        let session = try decoder.decode(Session.self, from: json)

        XCTAssertEqual(session.id, "sess_detail_001")
        XCTAssertEqual(session.task, "Refactor auth module")
        XCTAssertEqual(session.state, .planning)
    }

    // MARK: - Session Decoding (Minimal / Memberwise)

    func testSessionDecodingMinimalFields() throws {
        let json = """
        {
            "session_id": "sess_minimal",
            "task_text": "Quick fix",
            "status": "completed",
            "created_at": "2025-06-15T10:30:00Z",
            "updated_at": "2025-06-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let session = try decoder.decode(Session.self, from: json)

        XCTAssertEqual(session.id, "sess_minimal")
        XCTAssertEqual(session.state, .completed)
        XCTAssertNil(session.mode)
    }

    // MARK: - Session State Unknown Fallback

    func testSessionStateUnknownFallback() throws {
        let json = """
        {
            "session_id": "sess_unk",
            "task_text": "test",
            "status": "some_future_status",
            "created_at": "2025-06-15T10:30:00Z",
            "updated_at": "2025-06-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let session = try decoder.decode(Session.self, from: json)
        XCTAssertEqual(session.state, .unknown)
    }

    func testSessionStateTerminal() {
        XCTAssertTrue(SessionState.completed.isTerminal)
        XCTAssertTrue(SessionState.failed.isTerminal)
        XCTAssertTrue(SessionState.aborted.isTerminal)
        XCTAssertFalse(SessionState.running.isTerminal)
        XCTAssertFalse(SessionState.planning.isTerminal)
    }

    func testSessionStateActive() {
        XCTAssertTrue(SessionState.running.isActive)
        XCTAssertTrue(SessionState.planning.isActive)
        XCTAssertTrue(SessionState.live.isActive)
        XCTAssertTrue(SessionState.paused.isActive)
        XCTAssertFalse(SessionState.completed.isActive)
        XCTAssertFalse(SessionState.unknown.isActive)
    }

    // MARK: - JournalEvent Decoding

    func testJournalEventDecoding() throws {
        let json = """
        {
            "event_id": "evt_001",
            "timestamp": "2025-06-15T10:31:00.500Z",
            "session_id": "sess_abc123",
            "type": "step.completed",
            "payload": {
                "tool": "Edit",
                "file_path": "src/main.ts"
            },
            "seq": 5
        }
        """.data(using: .utf8)!

        let event = try decoder.decode(JournalEvent.self, from: json)

        XCTAssertEqual(event.eventId, "evt_001")
        XCTAssertEqual(event.id, "evt_001")
        XCTAssertEqual(event.sessionId, "sess_abc123")
        XCTAssertEqual(event.type, "step.completed")
        XCTAssertEqual(event.seq, 5)
        XCTAssertNotNil(event.payload)
        XCTAssertEqual(event.payload?["tool"]?.stringValue, "Edit")
    }

    func testJournalEventTypeLabel() {
        let event = JournalEvent(
            eventId: "evt_test",
            timestamp: Date(),
            sessionId: "s1",
            type: "planner.plan_generated",
            seq: 1
        )

        XCTAssertEqual(event.typeLabel, "Planner Plan Generated")
    }

    func testJournalEventPayloadSummary() {
        let event = JournalEvent(
            eventId: "evt_test",
            timestamp: Date(),
            sessionId: "s1",
            type: "step.started",
            payload: ["tool": AnyCodable("Read")],
            seq: 1
        )

        XCTAssertEqual(event.payloadSummary, "Tool: Read")
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
            mode: "manual",
            createdAt: Date(),
            updatedAt: Date()
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try decoder.decode(Session.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.task, original.task)
        XCTAssertEqual(decoded.state, original.state)
        XCTAssertEqual(decoded.mode, original.mode)
    }

    // MARK: - CreateSessionRequest Encoding

    func testCreateSessionRequestEncoding() throws {
        let request = CreateSessionRequest(text: "Build a REST API")
        let data = try JSONEncoder().encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["text"] as? String, "Build a REST API")
        XCTAssertNil(json?["task"]) // Should use "text", not "task"
    }
}
