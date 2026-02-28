import XCTest
@testable import Tarkus

// MARK: - SSEClientTests

/// Tests for the SSE event parsing logic in `KarnEvil9Event.parse(data:)`.
/// The actual API sends the event type inside the JSON `"type"` field rather
/// than on the SSE `event:` line. Each test constructs a realistic journal
/// event JSON and verifies correct categorization.
final class SSEClientTests: XCTestCase {

    // MARK: - Session Events

    func testParseSessionCreatedEvent() {
        let json = """
        {
            "event_id": "evt_sc_001",
            "timestamp": "2025-06-15T10:00:00.000Z",
            "session_id": "sess_start_001",
            "type": "session.created",
            "payload": {
                "task": "Build a REST API"
            },
            "seq": 1
        }
        """

        let event = KarnEvil9Event.parse(data: json)

        if case .sessionEvent(let journalEvent) = event {
            XCTAssertEqual(journalEvent.eventId, "evt_sc_001")
            XCTAssertEqual(journalEvent.sessionId, "sess_start_001")
            XCTAssertEqual(journalEvent.type, "session.created")
            XCTAssertEqual(journalEvent.seq, 1)
            XCTAssertEqual(journalEvent.payload?["task"]?.stringValue, "Build a REST API")
        } else {
            XCTFail("Expected .sessionEvent, got \(event)")
        }
    }

    func testParseSessionStartedEvent() {
        let json = """
        {
            "event_id": "evt_ss_001",
            "timestamp": "2025-06-15T10:00:01.000Z",
            "session_id": "sess_start_001",
            "type": "session.started",
            "seq": 2
        }
        """

        let event = KarnEvil9Event.parse(data: json)

        if case .sessionEvent(let journalEvent) = event {
            XCTAssertEqual(journalEvent.type, "session.started")
        } else {
            XCTFail("Expected .sessionEvent, got \(event)")
        }
    }

    // MARK: - Step Events

    func testParseStepStartedEvent() {
        let json = """
        {
            "event_id": "evt_step_001",
            "timestamp": "2025-06-15T10:01:00.000Z",
            "session_id": "sess_start_001",
            "type": "step.started",
            "payload": {
                "tool": "Read",
                "file_path": "package.json"
            },
            "seq": 3
        }
        """

        let event = KarnEvil9Event.parse(data: json)

        if case .stepEvent(let journalEvent) = event {
            XCTAssertEqual(journalEvent.type, "step.started")
            XCTAssertEqual(journalEvent.payload?["tool"]?.stringValue, "Read")
        } else {
            XCTFail("Expected .stepEvent, got \(event)")
        }
    }

    func testParseStepCompletedEvent() {
        let json = """
        {
            "event_id": "evt_step_002",
            "timestamp": "2025-06-15T10:01:03.500Z",
            "session_id": "sess_start_001",
            "type": "step.completed",
            "payload": {
                "tool": "Write",
                "file_path": "src/index.ts"
            },
            "seq": 4
        }
        """

        let event = KarnEvil9Event.parse(data: json)

        if case .stepEvent(let journalEvent) = event {
            XCTAssertEqual(journalEvent.type, "step.completed")
            XCTAssertEqual(journalEvent.payload?["tool"]?.stringValue, "Write")
        } else {
            XCTFail("Expected .stepEvent, got \(event)")
        }
    }

    // MARK: - Planner Events

    func testParsePlannerEvent() {
        let json = """
        {
            "event_id": "evt_plan_001",
            "timestamp": "2025-06-15T10:00:30.000Z",
            "session_id": "sess_start_001",
            "type": "planner.plan_generated",
            "payload": {
                "plan": "1. Read config\\n2. Implement feature"
            },
            "seq": 2
        }
        """

        let event = KarnEvil9Event.parse(data: json)

        if case .plannerEvent(let journalEvent) = event {
            XCTAssertEqual(journalEvent.type, "planner.plan_generated")
            XCTAssertNotNil(journalEvent.payload?["plan"])
        } else {
            XCTFail("Expected .plannerEvent, got \(event)")
        }
    }

    // MARK: - Approval Events

    func testParseApprovalRequestedEvent() {
        let json = """
        {
            "event_id": "evt_appr_001",
            "timestamp": "2025-06-15T10:02:00.000Z",
            "session_id": "sess_start_001",
            "type": "approval.requested",
            "payload": {
                "tool": "Bash",
                "command": "docker compose up -d"
            },
            "seq": 5
        }
        """

        let event = KarnEvil9Event.parse(data: json)

        if case .approvalEvent(let journalEvent) = event {
            XCTAssertEqual(journalEvent.type, "approval.requested")
            XCTAssertEqual(journalEvent.payload?["tool"]?.stringValue, "Bash")
        } else {
            XCTFail("Expected .approvalEvent, got \(event)")
        }
    }

    // MARK: - Unknown Event Type

    func testParseUnknownPrefixEvent() {
        let json = """
        {
            "event_id": "evt_unk_001",
            "timestamp": "2025-06-15T10:03:00.000Z",
            "session_id": "sess_start_001",
            "type": "metrics.updated",
            "payload": {
                "input_tokens": 1500
            },
            "seq": 6
        }
        """

        let event = KarnEvil9Event.parse(data: json)

        if case .unknown(let journalEvent) = event {
            XCTAssertEqual(journalEvent.type, "metrics.updated")
        } else {
            XCTFail("Expected .unknown, got \(event)")
        }
    }

    // MARK: - Error Handling

    func testParseMalformedDataReturnsError() {
        let badJson = "this is not json"

        let event = KarnEvil9Event.parse(data: badJson)

        if case .error(let message) = event {
            XCTAssertTrue(message.contains("Failed to parse"))
        } else {
            XCTFail("Expected .error, got \(event)")
        }
    }

    func testParseErrorPayload() {
        let json = """
        {
            "message": "Session timed out after 300 seconds of inactivity"
        }
        """

        // When the JSON doesn't decode as a JournalEvent but does decode
        // as an ErrorPayload, we should get an error event.
        let event = KarnEvil9Event.parse(data: json)

        if case .error(let message) = event {
            XCTAssertEqual(message, "Session timed out after 300 seconds of inactivity")
        } else {
            XCTFail("Expected .error, got \(event)")
        }
    }

    // MARK: - JournalEvent Round Trip

    func testJournalEventRoundTrip() throws {
        let original = JournalEvent(
            eventId: "evt_rt_001",
            timestamp: Date(),
            sessionId: "sess_001",
            type: "step.started",
            payload: ["tool": AnyCodable("Read"), "file": AnyCodable("main.ts")],
            seq: 3
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(JournalEvent.self, from: data)

        XCTAssertEqual(decoded.eventId, original.eventId)
        XCTAssertEqual(decoded.sessionId, original.sessionId)
        XCTAssertEqual(decoded.type, original.type)
        XCTAssertEqual(decoded.seq, original.seq)
        XCTAssertEqual(decoded.payload?["tool"]?.stringValue, "Read")
    }
}
