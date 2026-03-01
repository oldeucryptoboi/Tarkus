import Foundation

// MARK: - JournalEvent

/// A single event from the KarnEvil9 session journal, representing one
/// entry in the event stream (e.g. "session.created", "step.started", etc.).
struct JournalEvent: Codable, Identifiable, Equatable {
    let eventId: String
    let timestamp: Date
    let sessionId: String
    let type: String
    let payload: [String: AnyCodable]?
    let seq: Int

    var id: String { eventId }

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case timestamp
        case sessionId = "session_id"
        case type
        case payload
        case seq
    }

    // MARK: - Custom Decoding (ISO8601 dates)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        eventId = try container.decode(String.self, forKey: .eventId)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        type = try container.decode(String.self, forKey: .type)
        payload = try container.decodeIfPresent([String: AnyCodable].self, forKey: .payload)
        seq = try container.decodeIfPresent(Int.self, forKey: .seq) ?? 0

        let timestampString = try container.decode(String.self, forKey: .timestamp)
        timestamp = try Self.parseISO8601Date(timestampString, codingPath: container.codingPath + [CodingKeys.timestamp])
    }

    // MARK: - Custom Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(eventId, forKey: .eventId)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(payload, forKey: .payload)
        try container.encode(seq, forKey: .seq)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: timestamp), forKey: .timestamp)
    }

    // MARK: - Memberwise Initializer

    init(
        eventId: String,
        timestamp: Date,
        sessionId: String,
        type: String,
        payload: [String: AnyCodable]? = nil,
        seq: Int = 0
    ) {
        self.eventId = eventId
        self.timestamp = timestamp
        self.sessionId = sessionId
        self.type = type
        self.payload = payload
        self.seq = seq
    }

    // MARK: - Convenience

    /// A short human-readable label for the event type.
    var typeLabel: String {
        // "session.created" → "Session Created"
        type.replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    /// Returns a summary string from the payload, if available.
    var payloadSummary: String? {
        guard let payload = payload else { return nil }

        // Try common payload fields for a summary
        if let text = payload["text"]?.stringValue {
            return text
        }
        if let message = payload["message"]?.stringValue {
            return message
        }
        if let reason = payload["reason"]?.stringValue {
            return reason
        }
        if let error = payload["error"]?.stringValue {
            return error
        }
        if let plan = payload["plan"]?.stringValue {
            return plan
        }
        if let tool = payload["tool"]?.stringValue {
            return "Tool: \(tool)"
        }

        // Fallback: show number of payload keys
        return "\(payload.count) field\(payload.count == 1 ? "" : "s")"
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
