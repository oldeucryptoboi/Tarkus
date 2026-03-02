import SwiftUI

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - CodeHighlighterColorScheme

/// Represents the color scheme for code highlighting.
/// Mirrors OpenAI's `OAIMarkdown.CodeHighlighterColorScheme`.
///
/// OAI declares this as an enum; we use cases to represent light/dark.
enum CodeHighlighterColorScheme: Hashable {
    case light
    case dark

    init(colorScheme: ColorScheme) {
        self = colorScheme == .dark ? .dark : .light
    }

    #if canImport(AppKit)
    init(traitCollection: NSAppearance) {
        let name = traitCollection.bestMatch(from: [.darkAqua, .aqua])
        self = name == .darkAqua ? .dark : .light
    }
    #else
    init(traitCollection: UITraitCollection) {
        self = traitCollection.userInterfaceStyle == .dark ? .dark : .light
    }
    #endif

    /// The Highlightr theme name corresponding to this color scheme.
    /// Tarkus-specific — OAI handles this differently via Theme enum.
    var highlightrThemeName: String {
        switch self {
        case .dark: return "xcode-dark"
        case .light: return "xcode-light-custom"
        }
    }

    var isDark: Bool {
        self == .dark
    }
}
