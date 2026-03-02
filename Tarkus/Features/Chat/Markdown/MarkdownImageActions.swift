import Foundation
import SwiftUI

// MARK: - MarkdownImageActions

/// Configuration for image interaction actions in markdown content.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownImageActions`.
struct MarkdownImageActions {

    /// Returns the menu items for a given user role.
    var menu: @MainActor @Sendable (MarkdownContentUserRole) -> [MarkdownImageActionMenuItem]

    /// Handles a synchronous image action.
    var handler: (MarkdownImageAction) -> Void

    /// Handles an asynchronous image action.
    var asyncHandler: @MainActor @Sendable (MarkdownImageAsyncAction) async -> Void

    /// Creates image actions with no-op handlers.
    static var none: MarkdownImageActions {
        MarkdownImageActions(
            menu: { _ in [] },
            handler: { _ in },
            asyncHandler: { _ in }
        )
    }

    init(
        menu: @escaping @MainActor @Sendable (MarkdownContentUserRole) -> [MarkdownImageActionMenuItem],
        handler: @escaping (MarkdownImageAction) -> Void,
        asyncHandler: @escaping @MainActor @Sendable (MarkdownImageAsyncAction) async -> Void
    ) {
        self.menu = menu
        self.handler = handler
        self.asyncHandler = asyncHandler
    }
}

// MARK: - MarkdownImageAction

/// A synchronous action performed on an image in markdown content.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownImageAction`.
struct MarkdownImageAction {
    // Placeholder — OAI interface shows an empty struct.
    // Extend with specific action payloads as needed.
}

// MARK: - MarkdownImageAsyncAction

/// An asynchronous action performed on an image in markdown content.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownImageAsyncAction`.
struct MarkdownImageAsyncAction {
    // Placeholder — OAI interface shows an empty struct.
    // Extend with specific action payloads as needed.
}

// MARK: - MarkdownImageActionMenuItem

/// Menu items available for image actions.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownImageActionMenuItem`.
enum MarkdownImageActionMenuItem: Hashable {
    case save
    case share
    case copy
    case openInBrowser
}
