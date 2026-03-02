import Foundation
import Markdown

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MarkdownLinkParser

/// Protocol for custom link parsing in markdown content.
/// Implementations can transform links during compilation or provide custom views.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownLinkParser`.
protocol MarkdownLinkParser {

    /// Parse a markdown link and return a custom attributed string representation,
    /// or `nil` to use the default rendering.
    func parse(
        link: Markdown.Link,
        text: NSAttributedString,
        options: MarkdownOptions,
        attributeContext: MarkdownOptions.AttributeContext,
        traitCollection: PlatformAppearance
    ) -> NSAttributedString?

    /// Optionally provide a custom view for a link URL.
    /// Returns `nil` to use the default text representation.
    func view(for url: URL?, text: NSAttributedString) -> PlatformView?
}

// MARK: - Default Implementations

extension MarkdownLinkParser {
    func parse(
        link: Markdown.Link,
        text: NSAttributedString,
        options: MarkdownOptions,
        attributeContext: MarkdownOptions.AttributeContext = .initial,
        traitCollection: PlatformAppearance
    ) -> NSAttributedString? {
        nil
    }

    func view(for url: URL?, text: NSAttributedString) -> PlatformView? {
        nil
    }
}
