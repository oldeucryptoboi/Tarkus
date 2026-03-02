import Foundation

// MARK: - MarkdownTextSelectionHandlers

/// Callbacks for text selection events in markdown text blocks.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownTextSelectionHandlers`.
struct MarkdownTextSelectionHandlers {

    /// Called after the user copies selected text.
    var didCopy: ((SelectionRange) -> Void)?

    /// Called after the user performs "Select All".
    var didSelectAll: ((SelectionRange) -> Void)?

    /// Called whenever the text selection changes.
    var didChangeSelection: ((SelectionRange) -> Void)?

    init(
        didCopy: ((SelectionRange) -> Void)? = nil,
        didSelectAll: ((SelectionRange) -> Void)? = nil,
        didChangeSelection: ((SelectionRange) -> Void)? = nil
    ) {
        self.didCopy = didCopy
        self.didSelectAll = didSelectAll
        self.didChangeSelection = didChangeSelection
    }

    /// Default handlers with no callbacks.
    static var none: MarkdownTextSelectionHandlers {
        MarkdownTextSelectionHandlers()
    }

    // MARK: - SelectionRange

    /// Describes the extent of a text selection within a markdown block.
    struct SelectionRange {

        /// Number of characters in the current selection.
        var selectionLength: Int

        /// Total number of characters in the text block.
        var totalLength: Int

        /// The source view that owns the selection, if available.
        var source: MarkdownSelectionSource?

        /// The source of any detected entity within the selection.
        var detectedEntitySource: MarkdownSelectionDetectedEntitySource?

        /// The type of any detected entity within the selection.
        var detectedEntityType: MarkdownSelectionDetectedEntityType?

        /// Fraction of the total text that is selected (0.0 to 1.0), or `nil` if total is zero.
        var fraction: Float? {
            guard totalLength > 0 else { return nil }
            return Float(selectionLength) / Float(totalLength)
        }
    }
}

// MARK: - MarkdownSelectionDetectedEntityType

/// The type of entity detected within a text selection (e.g., URL, email).
/// Mirrors OpenAI's `OAIMarkdown.MarkdownSelectionDetectedEntityType`.
enum MarkdownSelectionDetectedEntityType: String, RawRepresentable, Hashable {
    case url
    case email
    case phoneNumber
    case address
}

// MARK: - MarkdownSelectionDetectedEntitySource

/// The source/context of a detected entity within a text selection.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownSelectionDetectedEntitySource`.
enum MarkdownSelectionDetectedEntitySource: String, RawRepresentable, Hashable {
    case inline
    case link
    case codeBlock
}
