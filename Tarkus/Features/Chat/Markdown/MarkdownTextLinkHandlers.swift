import Foundation
import SwiftUI

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MarkdownTextLinkHandlers

/// Callbacks and configuration for link interactions in markdown text.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownTextLinkHandlers`.
struct MarkdownTextLinkHandlers {

    /// Whether a link at the given URL should be loaded/opened.
    var shouldLoad: (URL) -> Bool

    /// Determines how a link interaction should be handled.
    var shouldInteract: (URL) -> Interaction

    /// Optional handler called when a link is tapped.
    /// Parameters: URL, display name, item index.
    var handle: ((URL, String?, Int) -> Void)?

    /// Called when a link is about to appear in the rendered content.
    /// Parameters: URL, item index.
    var willAppear: (URL, Int) -> Void

    /// Builds a context menu for a link.
    /// Parameters: URL, display name. Returns nil for no context menu.
    var contextMenuBuilder: (URL, String?) -> ContextMenu?

    init(
        shouldLoad: @escaping (URL) -> Bool,
        shouldInteract: @escaping (URL) -> Interaction,
        handle: ((URL, String?, Int) -> Void)? = nil,
        willAppear: @escaping (URL, Int) -> Void,
        contextMenuBuilder: @escaping (URL, String?) -> ContextMenu?
    ) {
        self.shouldLoad = shouldLoad
        self.shouldInteract = shouldInteract
        self.handle = handle
        self.willAppear = willAppear
        self.contextMenuBuilder = contextMenuBuilder
    }

    /// Opens a link, delegating to the handler or falling back to system open.
    func openLink(_ url: URL, name: String?, index: Int) {
        if let handle = handle {
            handle(url, name, index)
        } else {
            #if canImport(AppKit)
            NSWorkspace.shared.open(url)
            #else
            UIApplication.shared.open(url)
            #endif
        }
    }

    /// Default link handlers that open URLs via the system.
    static var `default`: MarkdownTextLinkHandlers {
        MarkdownTextLinkHandlers(
            shouldLoad: { _ in true },
            shouldInteract: { _ in .allow },
            handle: nil,
            willAppear: { _, _ in },
            contextMenuBuilder: { _, _ in nil }
        )
    }

    // MARK: - Interaction

    /// How a link interaction should be handled.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownTextLinkHandlers.Interaction`.
    enum Interaction: Hashable {
        /// Allow the default link behavior.
        case allow
        /// Prevent the link from being activated.
        case prevent
        /// Handle the link with a custom action.
        case custom
    }

    // MARK: - ContextMenu

    /// A context menu displayed for a link.
    struct ContextMenu {

        var items: [Item]

        init(items: [Item]) {
            self.items = items
        }

        // MARK: - Item

        /// A single item in a link context menu.
        struct Item {
            var title: String
            var action: @MainActor @Sendable () -> Void

            init(title: String, action: @escaping @MainActor @Sendable () -> Void) {
                self.title = title
                self.action = action
            }
        }
    }
}
