import Foundation

/// Represents all server-sent event types emitted by the KarnEvil9 SSE stream.
/// Events are categorized by the dot-notation `"type"` field found inside the
/// JSON data payload (e.g. `"session.created"`, `"step.started"`).
enum KarnEvil9Event {

    // Broad event categories wrapping the full JournalEvent
    case sessionEvent(JournalEvent)
    case stepEvent(JournalEvent)
    case plannerEvent(JournalEvent)
    case approvalEvent(JournalEvent)
    case error(message: String)
    case unknown(JournalEvent)

    // MARK: - Parsing

    /// Parses a raw JSON data string from the SSE stream into a typed `KarnEvil9Event`.
    /// The event type is read from the `"type"` field inside the JSON, not from
    /// the SSE `event:` line.
    static func parse(data: String) -> KarnEvil9Event {
        let decoder = JSONDecoder()
        return parse(data: data, decoder: decoder)
    }

    /// Parses a raw JSON data string into a typed `KarnEvil9Event` using the
    /// provided decoder.
    static func parse(data: String, decoder: JSONDecoder) -> KarnEvil9Event {
        guard let jsonData = data.data(using: .utf8) else {
            return .error(message: "Unable to convert SSE data to UTF-8")
        }

        do {
            let event = try decoder.decode(JournalEvent.self, from: jsonData)
            return categorize(event)
        } catch {
            // Try to extract just an error message if full decoding fails
            if let errorPayload = try? decoder.decode(ErrorPayload.self, from: jsonData) {
                return .error(message: errorPayload.message)
            }
            return .error(message: "Failed to parse SSE event: \(error.localizedDescription)")
        }
    }

    /// Categorizes a `JournalEvent` into the appropriate enum case based on
    /// its dot-notation type prefix.
    private static func categorize(_ event: JournalEvent) -> KarnEvil9Event {
        let type = event.type

        if type.hasPrefix("session.") {
            return .sessionEvent(event)
        } else if type.hasPrefix("step.") {
            return .stepEvent(event)
        } else if type.hasPrefix("planner.") {
            return .plannerEvent(event)
        } else if type.hasPrefix("approval.") {
            return .approvalEvent(event)
        } else {
            return .unknown(event)
        }
    }
}

// MARK: - Internal Payloads

/// Internal payload for decoding error-only SSE events.
private struct ErrorPayload: Codable {
    let message: String
}
