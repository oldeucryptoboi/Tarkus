import Foundation

/// Typed error enum representing all failure modes when communicating with
/// the KarnEvil9 REST and SSE APIs.
enum APIError: LocalizedError, Equatable {

    case invalidURL
    case unauthorized
    case httpError(statusCode: Int, message: String)
    case decodingError(String)
    case networkError(String)
    case sseError(String)
    case unknown

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .unauthorized:
            return "Authentication failed. Please check your API token."
        case .httpError(let statusCode, let message):
            return "HTTP \(statusCode): \(message)"
        case .decodingError(let detail):
            return "Failed to decode response: \(detail)"
        case .networkError(let detail):
            return "Network error: \(detail)"
        case .sseError(let detail):
            return "SSE stream error: \(detail)"
        case .unknown:
            return "An unknown error occurred."
        }
    }

    // MARK: - Convenience Initializers

    static func from(decodingError error: Error) -> APIError {
        .decodingError(error.localizedDescription)
    }

    static func from(networkError error: Error) -> APIError {
        .networkError(error.localizedDescription)
    }

    // MARK: - Equatable

    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL):
            return true
        case (.unauthorized, .unauthorized):
            return true
        case (.httpError(let lCode, let lMsg), .httpError(let rCode, let rMsg)):
            return lCode == rCode && lMsg == rMsg
        case (.decodingError(let l), .decodingError(let r)):
            return l == r
        case (.networkError(let l), .networkError(let r)):
            return l == r
        case (.sseError(let l), .sseError(let r)):
            return l == r
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
}
