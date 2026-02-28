import Foundation

/// Represents all server-sent event types emitted by the KarnEvil9 SSE stream.
/// Each case carries the decoded payload matching the event type.
enum KarnEvil9Event {

    // Session lifecycle
    case sessionStarted(Session)
    case sessionCompleted(Session)
    case sessionFailed(Session)
    case sessionAborted(Session)
    case sessionPaused(Session)
    case sessionResumed(Session)

    // Step lifecycle
    case stepStarted(Step)
    case stepCompleted(Step)
    case stepFailed(Step)

    // Tool execution
    case toolCallStarted(ToolCall)
    case toolResultReceived(ToolResult)

    // Assistant output
    case assistantMessage(id: String, content: String)

    // Permissions
    case permissionRequested(Approval)
    case permissionResolved(Approval)

    // Metrics
    case usageUpdated(UsageMetrics)

    // Errors and control
    case error(message: String)
    case heartbeat

    // MARK: - SSE Event Names

    /// The raw SSE event type strings sent by KarnEvil9.
    static let eventTypeSessionStarted      = "session_started"
    static let eventTypeSessionCompleted    = "session_completed"
    static let eventTypeSessionFailed       = "session_failed"
    static let eventTypeSessionAborted      = "session_aborted"
    static let eventTypeSessionPaused       = "session_paused"
    static let eventTypeSessionResumed      = "session_resumed"
    static let eventTypeStepStarted         = "step_started"
    static let eventTypeStepCompleted       = "step_completed"
    static let eventTypeStepFailed          = "step_failed"
    static let eventTypeToolCallStarted     = "tool_call_started"
    static let eventTypeToolResultReceived  = "tool_result_received"
    static let eventTypeAssistantMessage    = "assistant_message"
    static let eventTypePermissionRequested = "permission_requested"
    static let eventTypePermissionResolved  = "permission_resolved"
    static let eventTypeUsageUpdated        = "usage_updated"
    static let eventTypeError               = "error"
    static let eventTypeHeartbeat           = "heartbeat"

    // MARK: - Parsing

    /// Convenience overload that creates a default decoder.
    static func parse(eventType: String?, data: String) -> KarnEvil9Event {
        let decoder = JSONDecoder()
        do {
            return try parse(eventType: eventType ?? "heartbeat", data: data, decoder: decoder)
        } catch {
            return .error(message: "Failed to parse SSE event '\(eventType ?? "unknown")': \(error.localizedDescription)")
        }
    }

    /// Parses a raw SSE event into a typed `KarnEvil9Event`.
    ///
    /// - Parameters:
    ///   - eventType: The SSE event type string (e.g. `"session_started"`).
    ///   - data: The raw JSON data string from the SSE `data:` field.
    ///   - decoder: A configured `JSONDecoder` to use for deserialization.
    /// - Returns: The parsed `KarnEvil9Event`.
    /// - Throws: `APIError.decodingError` if the data cannot be decoded, or
    ///           `APIError.sseError` for unrecognized event types.
    static func parse(eventType: String, data: String, decoder: JSONDecoder) throws -> KarnEvil9Event {
        guard let jsonData = data.data(using: .utf8) else {
            throw APIError.sseError("Unable to convert SSE data to UTF-8 for event: \(eventType)")
        }

        do {
            switch eventType {

            // Session lifecycle
            case eventTypeSessionStarted:
                let session = try decoder.decode(Session.self, from: jsonData)
                return .sessionStarted(session)

            case eventTypeSessionCompleted:
                let session = try decoder.decode(Session.self, from: jsonData)
                return .sessionCompleted(session)

            case eventTypeSessionFailed:
                let session = try decoder.decode(Session.self, from: jsonData)
                return .sessionFailed(session)

            case eventTypeSessionAborted:
                let session = try decoder.decode(Session.self, from: jsonData)
                return .sessionAborted(session)

            case eventTypeSessionPaused:
                let session = try decoder.decode(Session.self, from: jsonData)
                return .sessionPaused(session)

            case eventTypeSessionResumed:
                let session = try decoder.decode(Session.self, from: jsonData)
                return .sessionResumed(session)

            // Step lifecycle
            case eventTypeStepStarted:
                let step = try decoder.decode(Step.self, from: jsonData)
                return .stepStarted(step)

            case eventTypeStepCompleted:
                let step = try decoder.decode(Step.self, from: jsonData)
                return .stepCompleted(step)

            case eventTypeStepFailed:
                let step = try decoder.decode(Step.self, from: jsonData)
                return .stepFailed(step)

            // Tool execution
            case eventTypeToolCallStarted:
                let toolCall = try decoder.decode(ToolCall.self, from: jsonData)
                return .toolCallStarted(toolCall)

            case eventTypeToolResultReceived:
                let toolResult = try decoder.decode(ToolResult.self, from: jsonData)
                return .toolResultReceived(toolResult)

            // Assistant output
            case eventTypeAssistantMessage:
                let payload = try decoder.decode(AssistantMessagePayload.self, from: jsonData)
                return .assistantMessage(id: payload.id, content: payload.content)

            // Permissions
            case eventTypePermissionRequested:
                let approval = try decoder.decode(Approval.self, from: jsonData)
                return .permissionRequested(approval)

            case eventTypePermissionResolved:
                let approval = try decoder.decode(Approval.self, from: jsonData)
                return .permissionResolved(approval)

            // Metrics
            case eventTypeUsageUpdated:
                let metrics = try decoder.decode(UsageMetrics.self, from: jsonData)
                return .usageUpdated(metrics)

            // Error
            case eventTypeError:
                let payload = try decoder.decode(ErrorPayload.self, from: jsonData)
                return .error(message: payload.message)

            // Heartbeat (data may be empty or a simple JSON object)
            case eventTypeHeartbeat:
                return .heartbeat

            default:
                throw APIError.sseError("Unrecognized SSE event type: \(eventType)")
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.from(decodingError: error)
        }
    }
}

// MARK: - Internal Payloads

/// Internal payload for decoding `assistant_message` SSE events.
private struct AssistantMessagePayload: Codable {
    let id: String
    let content: String
}

/// Internal payload for decoding `error` SSE events.
private struct ErrorPayload: Codable {
    let message: String
}
