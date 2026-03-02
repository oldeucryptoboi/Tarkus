import Foundation

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - CodeOnlyMarkdownPlugin

/// Plugin protocol for post-processing code-only markdown results.
/// Mirrors OpenAI's `OAIMarkdown.CodeOnlyMarkdownPlugin`.
protocol CodeOnlyMarkdownPlugin: AnyObject {
    func postProcess(result: inout CodeOnlyMarkdownResult, traitCollection: PlatformAppearance, options: MarkdownOptions)
}

// MARK: - CodeOnlyMarkdownResult

/// The result of parsing text for inline code and URL detection only,
/// without full markdown block-level parsing.
/// Mirrors OpenAI's `OAIMarkdown.CodeOnlyMarkdownResult`.
enum CodeOnlyMarkdownResult: Equatable {
    /// Plain text segment.
    case text(NSAttributedString)
    /// Inline code segment.
    case code(String)
    /// A detected URL.
    case url(URL, displayText: String)
}

// MARK: - CodeOnlyMarkdownCompiler

/// A lightweight compiler that only detects inline code and URLs in text,
/// without full markdown parsing.
/// Mirrors OpenAI's `OAIMarkdown.CodeOnlyMarkdownCompiler`.
struct CodeOnlyMarkdownCompiler {

    private let traitCollection: PlatformAppearance
    private let plugins: [CodeOnlyMarkdownPlugin]

    init(traitCollection: PlatformAppearance, plugins: [CodeOnlyMarkdownPlugin] = []) {
        self.traitCollection = traitCollection
        self.plugins = plugins
    }

    /// Parse text for inline code and URLs.
    ///
    /// - Parameters:
    ///   - text: The input text to parse.
    ///   - options: Markdown styling options.
    ///   - italicized: Whether the text should be italicized.
    ///   - lineLimit: Maximum number of lines to process.
    ///   - customAttributes: Custom attributes to apply at specific ranges.
    /// - Returns: A tuple of parsed results and whether the output was truncated.
    func parse(
        _ text: String,
        options: MarkdownOptions,
        italicized: Bool = false,
        lineLimit: Int = .max,
        customAttributes: [NSRange: Any] = [:]
    ) -> (result: [CodeOnlyMarkdownResult], truncated: Bool) {
        // Simple stub implementation: return the entire text as a single text result
        let attributes = options.defaultAttributes()
        let attributed = NSAttributedString(string: text, attributes: attributes)

        var result: CodeOnlyMarkdownResult = .text(attributed)
        for plugin in plugins {
            plugin.postProcess(result: &result, traitCollection: traitCollection, options: options)
        }

        return (result: [result], truncated: false)
    }
}
