import Foundation

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MarkdownCodeBlockHighlighter

/// Actor that wraps `HighlightrCodeHighlighter` for thread-safe async highlighting.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownCodeBlockHighlighter`.
///
/// JavaScriptCore initialization is expensive (~50ms), so the underlying
/// `HighlightrCodeHighlighter` is lazily created and reused.
actor MarkdownCodeBlockHighlighter {

    private var highlighter: HighlightrCodeHighlighter

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        // Stub — OAI declares this for custom executor support.
        // We return the default MainActor executor for now.
        MainActor.sharedUnownedExecutor
    }

    init(theme: HighlightrCodeHighlighter.Theme) {
        let colorScheme: CodeHighlighterColorScheme = theme == .xcodeDark ? .dark : .light
        self.highlighter = HighlightrCodeHighlighter(colorScheme: colorScheme, theme: theme)
    }

    /// Convenience init from a color scheme (derives theme automatically).
    init(colorScheme: CodeHighlighterColorScheme) {
        let theme: HighlightrCodeHighlighter.Theme = colorScheme.isDark ? .xcodeDark : .xcodeLightCustom
        self.highlighter = HighlightrCodeHighlighter(colorScheme: colorScheme, theme: theme)
    }

    /// Highlight code with optional language detection.
    func highlight(code: String, language: String?) -> NSAttributedString? {
        highlighter.highlight(code: code, language: language)
    }

    /// Update the color scheme (e.g., when switching dark/light mode).
    func updateColorScheme(_ colorScheme: CodeHighlighterColorScheme) {
        highlighter.colorScheme = colorScheme
    }
}
