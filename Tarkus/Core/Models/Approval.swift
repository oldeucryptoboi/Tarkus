import Foundation

// MARK: - Approval Decision

/// The decision a user can make when a tool requests permission.
enum ApprovalDecision: String, Codable, Equatable {
    case allowOnce = "allow_once"
    case allowAlways = "allow_always"
    case denyOnce = "deny_once"
    case denyAlways = "deny_always"
}

// MARK: - Permission

/// Describes the permission a tool is requesting from the user.
struct Permission: Codable, Equatable {
    let tool: String
    let description: String
    let input: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case tool
        case description
        case input
    }
}

// MARK: - Approval

/// An approval request from the KarnEvil9 API, representing a tool that
/// needs user permission before proceeding.
struct Approval: Codable, Identifiable, Equatable {
    let id: String
    let sessionId: String
    let permission: Permission
    let status: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case sessionId = "session_id"
        case permission
        case status
        case createdAt = "created_at"
    }

    // MARK: - Custom Decoding (ISO8601 dates)

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        permission = try container.decode(Permission.self, forKey: .permission)
        status = try container.decode(String.self, forKey: .status)

        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        createdAt = try Self.parseISO8601Date(createdAtString, codingPath: container.codingPath + [CodingKeys.createdAt])
    }

    // MARK: - Custom Encoding

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(permission, forKey: .permission)
        try container.encode(status, forKey: .status)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try container.encode(formatter.string(from: createdAt), forKey: .createdAt)
    }

    // MARK: - Memberwise Initializer

    init(
        id: String,
        sessionId: String,
        permission: Permission,
        status: String,
        createdAt: Date
    ) {
        self.id = id
        self.sessionId = sessionId
        self.permission = permission
        self.status = status
        self.createdAt = createdAt
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

// MARK: - Approval Response

/// The response body sent to the KarnEvil9 API when resolving an approval.
struct ApprovalResponse: Codable, Equatable {
    let decision: ApprovalDecision

    enum CodingKeys: String, CodingKey {
        case decision
    }
}
