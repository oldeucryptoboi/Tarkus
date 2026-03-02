#if canImport(AppKit)
import AppKit
import Quartz

// MARK: - MarkdownImageController

/// Mirrors OpenAI's `OAIMarkdown.MarkdownImageController`.
class MarkdownImageController {
    var items: [MarkdownImagePreviewItem] { [] }
}

// MARK: - MarkdownImagePreviewItem

/// Mirrors OpenAI's `OAIMarkdown.MarkdownImagePreviewItem`.
class MarkdownImagePreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?
    init() {}
}

// MARK: - MarkdownImagePreviewPanel

/// Mirrors OpenAI's `OAIMarkdown.MarkdownImagePreviewPanel`.
class MarkdownImagePreviewPanel {

    init(
        selection: MarkdownSelection.Images,
        window: NSWindow,
        imageDownloadRequestModifier: Any? = nil,
        onDismiss: @MainActor @Sendable () -> Void
    ) {
        // Stub
    }

    init(
        window: NSWindow,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil
    ) {
        // Stub
    }

    func update(selection: MarkdownSelection.Images) {}

    func beginPreviewPanelControl(_ panel: QLPreviewPanel?) {}

    func previewPanel(_ panel: QLPreviewPanel?, sourceFrameOnScreenFor item: QLPreviewItem?) -> CGRect {
        .zero
    }

    func previewPanel(_ panel: QLPreviewPanel?, transitionImageFor item: QLPreviewItem?, contentRect: UnsafeMutablePointer<CGRect>?) -> Any? {
        nil
    }
}

#endif
