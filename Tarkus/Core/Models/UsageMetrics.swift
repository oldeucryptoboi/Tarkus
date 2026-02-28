import Foundation

/// Token usage counts and cost tracking returned by the KarnEvil9 API.
struct UsageMetrics: Codable, Equatable {

    // MARK: - Properties

    let inputTokens: Int
    let outputTokens: Int
    let cacheReadTokens: Int
    let cacheWriteTokens: Int
    let totalCost: Double

    // MARK: - Computed Properties

    var totalTokens: Int {
        inputTokens + outputTokens
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
        case cacheReadTokens = "cache_read_tokens"
        case cacheWriteTokens = "cache_write_tokens"
        case totalCost = "total_cost"
    }

    // MARK: - Defaults

    static let zero = UsageMetrics(
        inputTokens: 0,
        outputTokens: 0,
        cacheReadTokens: 0,
        cacheWriteTokens: 0,
        totalCost: 0.0
    )
}
