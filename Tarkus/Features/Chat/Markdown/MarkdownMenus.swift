import Foundation
import SwiftUI

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MarkdownMenus

/// Configuration for edit and tap context menus on markdown text blocks.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownMenus`.
struct MarkdownMenus {

    /// Closure invoked when the user selects text and opens the edit menu.
    /// Returns an array of menu actions, or `nil` for the default system menu.
    var edit: (MarkdownTextSelectionHandlers.SelectionRange, NSAttributedString) -> [MarkdownMenuAction]?

    /// Optional closure invoked on text tap.
    /// Returns an array of tap menu items, or `nil` if no tap menu should appear.
    var tap: ((MarkdownTextSelectionHandlers.SelectionRange, NSAttributedString) -> [MarkdownTextTapMenuItem]?)?

    init(
        edit: @escaping (MarkdownTextSelectionHandlers.SelectionRange, NSAttributedString) -> [MarkdownMenuAction]?,
        tap: ((MarkdownTextSelectionHandlers.SelectionRange, NSAttributedString) -> [MarkdownTextTapMenuItem]?)? = nil
    ) {
        self.edit = edit
        self.tap = tap
    }

    /// Default menus with no custom actions.
    static var none: MarkdownMenus {
        MarkdownMenus(edit: { _, _ in nil }, tap: nil)
    }
}

// MARK: - MarkdownMenuAction

/// A single action item displayed in the markdown edit context menu.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownMenuAction`.
struct MarkdownMenuAction {

    let title: String
    let image: PlatformImage?
    let handler: () -> Void

    init(title: String, image: @autoclosure () -> PlatformImage?, handler: @escaping () -> Void) {
        self.title = title
        self.image = image()
        self.handler = handler
    }
}

// MARK: - MarkdownTextTapMenuItem

/// An item displayed when tapping on markdown text.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownTextTapMenuItem`.
struct MarkdownTextTapMenuItem {

    let label: Label
    let handler: () -> Void

    init(label: Label, handler: @escaping () -> Void) {
        self.label = label
        self.handler = handler
    }

    // MARK: - Label

    /// Visual label for the tap menu item.
    struct Label {
        let title: String
        let image: PlatformImage?

        init(title: String, image: @autoclosure () -> PlatformImage?) {
            self.title = title
            self.image = image()
        }
    }
}
