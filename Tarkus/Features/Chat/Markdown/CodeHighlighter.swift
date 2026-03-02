import Foundation

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - CodeHighlighter

/// Protocol for syntax highlighting code strings.
/// Mirrors OpenAI's `OAIMarkdown.CodeHighlighter`.
protocol CodeHighlighter {
    func highlight(code: String, language: String?) -> NSAttributedString?
}
