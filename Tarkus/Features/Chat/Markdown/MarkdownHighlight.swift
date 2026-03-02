import Foundation
import CoreGraphics

// MARK: - MarkdownHighlight

/// Represents highlighted regions in rendered markdown content (e.g., search results).
/// Mirrors OpenAI's `OAIMarkdown.MarkdownHighlight`.
struct MarkdownHighlight {
    /// The frames of the highlighted text regions.
    var frames: [CGRect]

    init(frames: [CGRect] = []) {
        self.frames = frames
    }
}

// MARK: - IdentifiableMarkdownReferencePath

/// An identifiable wrapper around `MarkdownReferencePath` for use in ForEach and collections.
/// Mirrors OpenAI's `OAIMarkdown.IdentifiableMarkdownReferencePath`.
struct IdentifiableMarkdownReferencePath: Identifiable {

    var id: AnyHashable
    var path: MarkdownReferencePath

    init(id: AnyHashable, path: MarkdownReferencePath) {
        self.id = id
        self.path = path
    }
}

// MARK: - MarkdownSourceRangeTransformer

/// Maps source string ranges to reference paths in a compiled `MarkdownResult`.
/// Used for find-in-page and highlight coordination.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownSourceRangeTransformer`.
struct MarkdownSourceRangeTransformer {

    /// The original markdown source string.
    var source: String

    /// The compiled result from the source.
    var result: MarkdownResult

    init(source: String, result: MarkdownResult) {
        self.source = source
        self.result = result
    }

    /// Maps a range in the source string to reference paths in the compiled result.
    func referencePaths(for range: Range<String.Index>) -> [MarkdownReferencePath] {
        // Stub — will be implemented when we support find-in-page
        return []
    }
}

// MARK: - MarkdownInlineAttributes

/// Codable inline attributes for markdown content, used for serialization.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownInlineAttributes`.
struct MarkdownInlineAttributes: Codable {

    /// An encoded string representation of the attributes, if available.
    var encoded: String?

    init(encoded: String? = nil) {
        self.encoded = encoded
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case encoded
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(encoded, forKey: .encoded)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.encoded = try container.decodeIfPresent(String.self, forKey: .encoded)
    }
}
