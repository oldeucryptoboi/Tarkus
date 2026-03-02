import Foundation
import Highlightr

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - HighlightrCodeHighlighter

/// Wraps the `Highlightr` library to provide syntax highlighting.
/// Mirrors OpenAI's `OAIMarkdown.HighlightrCodeHighlighter`.
///
/// OAI declares this as a non-final class with a nested Theme enum.
class HighlightrCodeHighlighter: CodeHighlighter {

    // MARK: - Theme

    /// Nested theme enum for selecting a highlight.js theme.
    /// Mirrors OpenAI's `OAIMarkdown.HighlightrCodeHighlighter.Theme`.
    enum Theme: Hashable {
        case xcodeDark
        case xcodeLightCustom

        /// The highlight.js theme name for Highlightr's `setTheme(to:)`.
        var highlightrThemeName: String {
            switch self {
            case .xcodeDark: return "xcode-dark"
            case .xcodeLightCustom: return "xcode-light-custom"
            }
        }
    }

    // MARK: - Properties

    let theme: Theme

    var colorScheme: CodeHighlighterColorScheme {
        didSet {
            guard colorScheme != oldValue else { return }
            updateHighlightrTheme()
        }
    }

    private lazy var highlightr: Highlightr? = {
        let instance = Highlightr()
        if let instance = instance {
            // Install custom theme if not already present
            Self.installCustomThemeIfNeeded()

            instance.setTheme(to: colorScheme.highlightrThemeName)
            instance.theme.themeBackgroundColor = PlatformColor.clear
        }
        return instance
    }()

    /// Copies `xcode-light-custom.min.css` from our app bundle into the
    /// Highlightr resource bundle so `setTheme(to:)` can find it.
    private static func installCustomThemeIfNeeded() {
        guard let srcURL = Bundle.main.url(forResource: "xcode-light-custom.min", withExtension: "css") else { return }

        // Find the Highlightr resource bundle
        guard let highlightrBundle = Bundle.main.url(
            forResource: "Highlightr_Highlightr", withExtension: "bundle"
        ) else { return }

        #if canImport(AppKit)
        // macOS bundles have Contents/Resources/
        let destDir = highlightrBundle.appendingPathComponent("Contents/Resources")
        #else
        let destDir = highlightrBundle
        #endif

        let destURL = destDir.appendingPathComponent("xcode-light-custom.min.css")
        guard !FileManager.default.fileExists(atPath: destURL.path) else { return }

        try? FileManager.default.copyItem(at: srcURL, to: destURL)
    }

    // MARK: - Init

    init(colorScheme: CodeHighlighterColorScheme, theme: Theme) {
        self.colorScheme = colorScheme
        self.theme = theme
    }

    /// Convenience init that derives theme from color scheme.
    convenience init(colorScheme: CodeHighlighterColorScheme) {
        let theme: Theme = colorScheme.isDark ? .xcodeDark : .xcodeLightCustom
        self.init(colorScheme: colorScheme, theme: theme)
    }

    // MARK: - CodeHighlighter

    func highlight(code: String, language: String?) -> NSAttributedString? {
        guard let highlightr = highlightr else { return nil }
        let lang = normalizeLanguage(language)
        return highlightr.highlight(code, as: lang)
    }

    // MARK: - Private

    private func updateHighlightrTheme() {
        guard let highlightr = highlightr else { return }
        highlightr.setTheme(to: colorScheme.highlightrThemeName)
        highlightr.theme.themeBackgroundColor = PlatformColor.clear
    }

    /// Normalize common language aliases to names Highlightr recognizes.
    private func normalizeLanguage(_ language: String?) -> String? {
        guard let lang = language?.lowercased().trimmingCharacters(in: .whitespaces),
              !lang.isEmpty else {
            return nil
        }

        let aliases: [String: String] = [
            "js": "javascript",
            "ts": "typescript",
            "py": "python",
            "rb": "ruby",
            "sh": "bash",
            "shell": "bash",
            "zsh": "bash",
            "yml": "yaml",
            "objc": "objectivec",
            "objective-c": "objectivec",
            "kt": "kotlin",
            "rs": "rust",
            "cs": "csharp",
            "c#": "csharp",
            "f#": "fsharp",
            "md": "markdown",
            "dockerfile": "docker",
            "jsonc": "json",
            "jsx": "javascript",
            "tsx": "typescript",
        ]

        return aliases[lang] ?? lang
    }
}
