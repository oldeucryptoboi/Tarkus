import Foundation

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - HTMLRepresentable

/// Protocol for types that can produce an HTML representation.
/// Mirrors OpenAI's `OAIMarkdown.HTMLRepresentable`.
protocol HTMLRepresentable {
    var asHTML: String { get }
}

// MARK: - MarkdownSourcePosition

/// Placeholder typealias for source position tracking.
/// OAI uses `AttributedString.MarkdownSourcePosition`; we use an optional Any
/// until we adopt Foundation.AttributedString throughout.
typealias MarkdownSourcePosition = Any

// MARK: - MarkdownReferencePath

/// Placeholder for reference path matching in markdown content.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownReferencePath`.
enum MarkdownReferencePath: Equatable {
    // Stub — will be expanded when we implement find-in-page

    /// Returns a reference path scoped to a specific item index, or nil.
    func itemReferencePath(with index: Int) -> MarkdownReferencePath? {
        // Stub
        nil
    }
}

// MARK: - Platform Type Aliases

#if canImport(AppKit)
typealias PlatformView = NSView
typealias PlatformTextAttachment = NSTextAttachment
#else
typealias PlatformView = UIView
typealias PlatformTextAttachment = NSTextAttachment
#endif

// MARK: - MarkdownResult

/// The compiled output of a markdown string — a list of block-level items.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownResult`.
struct MarkdownResult: Equatable, HTMLRepresentable {

    var items: [Item]
    var imageMetadata: [URL: Any]

    init(items: [Item] = [], imageMetadata: [URL: Any] = [:]) {
        self.items = items
        self.imageMetadata = imageMetadata
    }

    // MARK: - HTMLRepresentable

    var asHTML: String {
        // Stub — will be implemented when we add HTML export
        return ""
    }

    // MARK: - Reference Path Matching

    /// Find matching reference paths using a string matcher.
    /// Stub implementation — will be expanded for find-in-page.
    func findMatchingReferencePaths(using matcher: (String) -> [Range<String.Index>]) -> [MarkdownReferencePath] {
        // Stub
        return []
    }

    // MARK: - AttributedContent

    /// Produce a single attributed content representation of all items.
    func attributedContent(with appearance: PlatformAppearance) -> AttributedContent {
        // Stub — returns concatenation of text items for now
        let combined = NSMutableAttributedString()
        for item in items {
            switch item {
            case .text(let t):
                combined.append(t.text)
            default:
                break
            }
        }
        return AttributedContent(text: combined, attachments: [:])
    }

    // MARK: - AttributedContent

    /// Combined attributed text and view attachments for a result.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownResult.AttributedContent`.
    struct AttributedContent {
        var text: NSAttributedString
        var attachments: [TextAttachment: PlatformView]

        static func empty() -> AttributedContent {
            AttributedContent(text: NSAttributedString(), attachments: [:])
        }
    }

    // MARK: - TextAttachment

    /// A text attachment with optional vertical offset for baseline alignment.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownResult.TextAttachment`.
    struct TextAttachment: Hashable {
        var attachment: PlatformTextAttachment
        var verticalOffset: CGFloat?

        static func == (lhs: TextAttachment, rhs: TextAttachment) -> Bool {
            lhs.attachment === rhs.attachment && lhs.verticalOffset == rhs.verticalOffset
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(attachment))
            hasher.combine(verticalOffset)
        }
    }

    // MARK: - Equatable

    static func == (lhs: MarkdownResult, rhs: MarkdownResult) -> Bool {
        lhs.items == rhs.items
        // imageMetadata uses [URL: Any] so we skip it for equality
    }

    // MARK: - Item

    /// A single block-level item in the rendered markdown output.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownResult.Item`.
    /// Note: OAI does not conform Item to Identifiable. We keep an internal `id`
    /// property for ForEach usage but do not declare protocol conformance.
    enum Item: Equatable {

        case text(Text)
        case code(Code)
        case table(MarkdownTable)
        case images([Image])

        // Tarkus internal id for ForEach usage — not in OAI
        var id: String {
            switch self {
            case .text(let t): return "text-\(t.text.string.hashValue)"
            case .code(let c): return "code-\(c.code.hashValue)"
            case .table(let t): return "table-\(t.hashValue)"
            case .images(let imgs): return "images-\(imgs.hashValue)"
            }
        }

        var kind: Kind {
            switch self {
            case .text: return .text
            case .code: return .code
            case .table: return .table
            case .images: return .images
            }
        }

        /// The attributed text content if this is a text item, nil otherwise.
        var text: NSAttributedString? {
            switch self {
            case .text(let t): return t.text
            default: return nil
            }
        }

        /// View attachments if this is a text item, nil otherwise.
        var viewAttachments: [TextAttachment: PlatformView]? {
            switch self {
            case .text(let t): return t.viewAttachments
            default: return nil
            }
        }

        /// Produce attributed content for this item with the given appearance.
        func attributedContent(with appearance: PlatformAppearance) -> AttributedContent? {
            switch self {
            case .text(let t):
                return AttributedContent(text: t.text, attachments: t.viewAttachments)
            default:
                return nil
            }
        }

        // MARK: - Item.Kind

        /// Discriminator for item types.
        /// Mirrors OpenAI's `OAIMarkdown.MarkdownResult.Item.Kind`.
        enum Kind: Hashable {
            case text
            case code
            case table
            case images
        }

        // MARK: - Item.Text

        /// A text block containing styled attributed content.
        /// Lists and blockquotes are compiled into text items with
        /// paragraph styling (indentation, tab stops).
        /// Mirrors OpenAI's `OAIMarkdown.MarkdownResult.Item.Text`.
        struct Text: Equatable {
            var text: NSAttributedString
            var viewAttachments: [TextAttachment: PlatformView]

            // Tarkus extension - not in OAI: heading level for dispatch in MarkdownBlockStack
            var headingLevel: Int?

            // Tarkus extension: marks text items that should render with a blockquote bar
            var isBlockquote: Bool

            init(text: NSAttributedString, viewAttachments: [TextAttachment: PlatformView] = [:], headingLevel: Int? = nil, isBlockquote: Bool = false) {
                self.text = text
                self.viewAttachments = viewAttachments
                self.headingLevel = headingLevel
                self.isBlockquote = isBlockquote
            }

            init(text: String) {
                self.text = NSAttributedString(string: text)
                self.viewAttachments = [:]
                self.headingLevel = nil
                self.isBlockquote = false
            }

            // Convenience initializer matching old `plainText:` pattern
            init(plainText: String) {
                self.text = NSAttributedString(string: plainText)
                self.viewAttachments = [:]
                self.headingLevel = nil
                self.isBlockquote = false
            }

            static func == (lhs: Text, rhs: Text) -> Bool {
                lhs.text.isEqual(to: rhs.text)
                    && lhs.headingLevel == rhs.headingLevel
                    && lhs.isBlockquote == rhs.isBlockquote
                // viewAttachments contain views — skip for equality
            }
        }

        // MARK: - Item.Code

        /// A fenced code block with optional language annotation.
        /// Mirrors OpenAI's `OAIMarkdown.MarkdownResult.Item.Code`.
        struct Code: Equatable {
            var code: String
            var language: String?
            var sourcePosition: MarkdownSourcePosition?

            init(code: String, language: String? = nil, sourcePosition: MarkdownSourcePosition? = nil) {
                self.code = code
                self.language = language
                self.sourcePosition = sourcePosition
            }

            static func == (lhs: Code, rhs: Code) -> Bool {
                lhs.code == rhs.code && lhs.language == rhs.language
                // sourcePosition is Any — skip for equality
            }
        }

        // MARK: - Item.Image

        /// An image reference from markdown content.
        /// Mirrors OpenAI's `OAIMarkdown.MarkdownResult.Item.Image`.
        struct Image: Hashable {
            var url: URL
            var title: String?
            var link: URL?
            var urlAttribution: String?
            var transitionSourceID: String?
            var sourcePosition: MarkdownSourcePosition?

            init(
                url: URL,
                title: String? = nil,
                link: URL? = nil,
                urlAttribution: String? = nil,
                transitionSourceID: String? = nil,
                sourcePosition: MarkdownSourcePosition? = nil
            ) {
                self.url = url
                self.title = title
                self.link = link
                self.urlAttribution = urlAttribution
                self.transitionSourceID = transitionSourceID
                self.sourcePosition = sourcePosition
            }

            static func == (lhs: Image, rhs: Image) -> Bool {
                lhs.url == rhs.url
                    && lhs.title == rhs.title
                    && lhs.link == rhs.link
                    && lhs.urlAttribution == rhs.urlAttribution
                    && lhs.transitionSourceID == rhs.transitionSourceID
                // sourcePosition is Any — skip for equality
            }

            func hash(into hasher: inout Hasher) {
                hasher.combine(url)
                hasher.combine(title)
                hasher.combine(link)
                hasher.combine(urlAttribution)
                hasher.combine(transitionSourceID)
            }
        }
    }
}
