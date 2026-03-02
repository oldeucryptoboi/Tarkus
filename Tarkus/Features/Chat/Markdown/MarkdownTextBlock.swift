import SwiftUI

#if canImport(AppKit)
import AppKit

// MARK: - MarkdownTextBlock (macOS)

/// SwiftUI bridge wrapping `MarkdownTextBlockView`.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownTextBlock`.
struct MarkdownTextBlock: NSViewRepresentable {

    let attributedText: NSAttributedString
    let viewAttachments: [MarkdownResult.TextAttachment: NSView]
    let markdownOptions: MarkdownOptions
    let fadeAnimatorConfiguration: TextFadeAnimator.Configuration
    let uniqueIdentifier: AnyHashable?
    let streaming: Bool
    let hapticFadeIn: Bool
    let hugsTextHorizontally: Bool
    let lineLimit: Int
    let linkHandlers: MarkdownTextLinkHandlers
    let selectionHandlers: MarkdownTextSelectionHandlers
    let menus: MarkdownMenus
    let insertionRanges: [InsertionRange]
    let activeHighlightIDs: Set<String>
    let highlightFramesUpdatedHandler: (([String: CGRect]) -> ())?
    let entityDetectionEnabled: Bool

    init(
        attributedText: NSAttributedString,
        viewAttachments: [MarkdownResult.TextAttachment: NSView] = [:],
        markdownOptions: MarkdownOptions = .init(),
        fadeAnimatorConfiguration: TextFadeAnimator.Configuration = .init(),
        uniqueIdentifier: AnyHashable? = nil,
        streaming: Bool = false,
        hapticFadeIn: Bool = false,
        hugsTextHorizontally: Bool = false,
        lineLimit: Int = 0,
        linkHandlers: MarkdownTextLinkHandlers = .default,
        selectionHandlers: MarkdownTextSelectionHandlers = .none,
        menus: MarkdownMenus = .none,
        insertionRanges: [InsertionRange] = [],
        activeHighlightIDs: Set<String> = [],
        highlightFramesUpdatedHandler: (([String: CGRect]) -> ())? = nil,
        entityDetectionEnabled: Bool = false
    ) {
        self.attributedText = attributedText
        self.viewAttachments = viewAttachments
        self.markdownOptions = markdownOptions
        self.fadeAnimatorConfiguration = fadeAnimatorConfiguration
        self.uniqueIdentifier = uniqueIdentifier
        self.streaming = streaming
        self.hapticFadeIn = hapticFadeIn
        self.hugsTextHorizontally = hugsTextHorizontally
        self.lineLimit = lineLimit
        self.linkHandlers = linkHandlers
        self.selectionHandlers = selectionHandlers
        self.menus = menus
        self.insertionRanges = insertionRanges
        self.activeHighlightIDs = activeHighlightIDs
        self.highlightFramesUpdatedHandler = highlightFramesUpdatedHandler
        self.entityDetectionEnabled = entityDetectionEnabled
    }

    // MARK: - InsertionRange

    /// Describes a range within attributed text where content can be inserted.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownTextBlock.InsertionRange`.
    struct InsertionRange {
        var id: AnyHashable
        var range: NSRange
    }

    // MARK: - Coordinator

    /// Coordinator for managing NSView lifecycle.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownTextBlock.Coordinator`.
    class Coordinator {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - triggerSelectAll

    /// Returns a copy of this view configured to trigger a select-all action.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownTextBlock.triggerSelectAll(_:)`.
    func triggerSelectAll(_ id: AnyHashable?) -> MarkdownTextBlock {
        // Stub — returns self unchanged for now
        return self
    }

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> MarkdownTextBlockView {
        let view = MarkdownTextBlockView(frame: .zero)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return view
    }

    func updateNSView(_ view: MarkdownTextBlockView, context: Context) {
        view.attributedText = attributedText
    }

    @MainActor
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView view: MarkdownTextBlockView,
        context: Context
    ) -> CGSize? {
        let width = proposal.width ?? view.bounds.width
        guard width > 0 else { return nil }
        view.frame.size.width = width
        view.layoutSubtreeIfNeeded()
        let intrinsic = view.intrinsicContentSize
        return CGSize(width: width, height: max(intrinsic.height, 1))
    }
}

#else
import UIKit

// MARK: - MarkdownTextBlock (iOS)

/// SwiftUI bridge wrapping `MarkdownTextBlockView`.
struct MarkdownTextBlock: UIViewRepresentable {

    let attributedText: NSAttributedString
    let viewAttachments: [MarkdownResult.TextAttachment: UIView]
    let markdownOptions: MarkdownOptions
    let fadeAnimatorConfiguration: TextFadeAnimator.Configuration
    let uniqueIdentifier: AnyHashable?
    let streaming: Bool
    let hapticFadeIn: Bool
    let hugsTextHorizontally: Bool
    let lineLimit: Int
    let linkHandlers: MarkdownTextLinkHandlers
    let selectionHandlers: MarkdownTextSelectionHandlers
    let menus: MarkdownMenus
    let insertionRanges: [InsertionRange]
    let activeHighlightIDs: Set<String>
    let highlightFramesUpdatedHandler: (([String: CGRect]) -> ())?
    let entityDetectionEnabled: Bool

    init(
        attributedText: NSAttributedString,
        viewAttachments: [MarkdownResult.TextAttachment: UIView] = [:],
        markdownOptions: MarkdownOptions = .init(),
        fadeAnimatorConfiguration: TextFadeAnimator.Configuration = .init(),
        uniqueIdentifier: AnyHashable? = nil,
        streaming: Bool = false,
        hapticFadeIn: Bool = false,
        hugsTextHorizontally: Bool = false,
        lineLimit: Int = 0,
        linkHandlers: MarkdownTextLinkHandlers = .default,
        selectionHandlers: MarkdownTextSelectionHandlers = .none,
        menus: MarkdownMenus = .none,
        insertionRanges: [InsertionRange] = [],
        activeHighlightIDs: Set<String> = [],
        highlightFramesUpdatedHandler: (([String: CGRect]) -> ())? = nil,
        entityDetectionEnabled: Bool = false
    ) {
        self.attributedText = attributedText
        self.viewAttachments = viewAttachments
        self.markdownOptions = markdownOptions
        self.fadeAnimatorConfiguration = fadeAnimatorConfiguration
        self.uniqueIdentifier = uniqueIdentifier
        self.streaming = streaming
        self.hapticFadeIn = hapticFadeIn
        self.hugsTextHorizontally = hugsTextHorizontally
        self.lineLimit = lineLimit
        self.linkHandlers = linkHandlers
        self.selectionHandlers = selectionHandlers
        self.menus = menus
        self.insertionRanges = insertionRanges
        self.activeHighlightIDs = activeHighlightIDs
        self.highlightFramesUpdatedHandler = highlightFramesUpdatedHandler
        self.entityDetectionEnabled = entityDetectionEnabled
    }

    // MARK: - InsertionRange

    /// Describes a range within attributed text where content can be inserted.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownTextBlock.InsertionRange`.
    struct InsertionRange {
        var id: AnyHashable
        var range: NSRange
    }

    // MARK: - Coordinator

    /// Coordinator for managing UIView lifecycle.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownTextBlock.Coordinator`.
    class Coordinator {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - triggerSelectAll

    /// Returns a copy of this view configured to trigger a select-all action.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownTextBlock.triggerSelectAll(_:)`.
    func triggerSelectAll(_ id: AnyHashable?) -> MarkdownTextBlock {
        // Stub — returns self unchanged for now
        return self
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> MarkdownTextBlockView {
        let view = MarkdownTextBlockView(frame: .zero)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return view
    }

    func updateUIView(_ view: MarkdownTextBlockView, context: Context) {
        view.attributedText = attributedText
    }

    @MainActor
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView view: MarkdownTextBlockView,
        context: Context
    ) -> CGSize? {
        let width = proposal.width ?? view.bounds.width
        view.frame.size.width = width
        view.layoutSubviews()
        let intrinsic = view.intrinsicContentSize
        return CGSize(width: width, height: intrinsic.height)
    }
}

#endif
