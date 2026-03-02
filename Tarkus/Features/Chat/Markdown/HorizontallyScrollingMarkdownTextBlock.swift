import SwiftUI

#if canImport(AppKit)
import AppKit

// MARK: - HorizontallyScrollingMarkdownTextBlock (macOS)

/// SwiftUI bridge for `HorizontallyScrollingMarkdownTextView`.
/// Used inside `MarkdownCodeBlock` for horizontally scrollable code content.
/// Mirrors OpenAI's `OAIMarkdown.HorizontallyScrollingMarkdownTextBlock`.
struct HorizontallyScrollingMarkdownTextBlock: NSViewRepresentable {

    let attributedText: NSAttributedString
    let viewAttachments: [MarkdownResult.TextAttachment: NSView]
    let markdownOptions: MarkdownOptions
    let uniqueIdentifier: AnyHashable?
    let streaming: Bool
    let hapticFadeIn: Bool
    let showsHorizontalScrollIndicator: Bool
    let horizontalScrollIndicatorInset: CGFloat
    let isScrollEnabled: Bool
    let linkHandlers: MarkdownTextLinkHandlers
    let selectionHandlers: MarkdownTextSelectionHandlers
    let menus: MarkdownMenus

    init(
        attributedText: NSAttributedString,
        viewAttachments: [MarkdownResult.TextAttachment: NSView] = [:],
        markdownOptions: MarkdownOptions = .init(),
        uniqueIdentifier: AnyHashable? = nil,
        streaming: Bool = false,
        hapticFadeIn: Bool = false,
        showsHorizontalScrollIndicator: Bool = false,
        horizontalScrollIndicatorInset: CGFloat = 0,
        isScrollEnabled: Bool = true,
        linkHandlers: MarkdownTextLinkHandlers = .default,
        selectionHandlers: MarkdownTextSelectionHandlers = .none,
        menus: MarkdownMenus = .none
    ) {
        self.attributedText = attributedText
        self.viewAttachments = viewAttachments
        self.markdownOptions = markdownOptions
        self.uniqueIdentifier = uniqueIdentifier
        self.streaming = streaming
        self.hapticFadeIn = hapticFadeIn
        self.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        self.horizontalScrollIndicatorInset = horizontalScrollIndicatorInset
        self.isScrollEnabled = isScrollEnabled
        self.linkHandlers = linkHandlers
        self.selectionHandlers = selectionHandlers
        self.menus = menus
    }

    // MARK: - Coordinator

    /// Coordinator for managing NSView lifecycle.
    /// Mirrors OpenAI's `OAIMarkdown.HorizontallyScrollingMarkdownTextBlock.Coordinator`.
    class Coordinator {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - triggerSelectAll

    /// Returns a copy of this view configured to trigger a select-all action.
    /// Mirrors OpenAI's `OAIMarkdown.HorizontallyScrollingMarkdownTextBlock.triggerSelectAll(_:)`.
    func triggerSelectAll(_ id: AnyHashable?) -> HorizontallyScrollingMarkdownTextBlock {
        // Stub — returns self unchanged for now
        return self
    }

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> HorizontallyScrollingMarkdownTextView {
        let view = HorizontallyScrollingMarkdownTextView(frame: .zero)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return view
    }

    func updateNSView(_ view: HorizontallyScrollingMarkdownTextView, context: Context) {
        view.attributedText = attributedText
    }

    @MainActor
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView view: HorizontallyScrollingMarkdownTextView,
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

// MARK: - HorizontallyScrollingMarkdownTextBlock (iOS)

struct HorizontallyScrollingMarkdownTextBlock: UIViewRepresentable {

    let attributedText: NSAttributedString
    let viewAttachments: [MarkdownResult.TextAttachment: UIView]
    let markdownOptions: MarkdownOptions
    let uniqueIdentifier: AnyHashable?
    let streaming: Bool
    let hapticFadeIn: Bool
    let showsHorizontalScrollIndicator: Bool
    let horizontalScrollIndicatorInset: CGFloat
    let isScrollEnabled: Bool
    let linkHandlers: MarkdownTextLinkHandlers
    let selectionHandlers: MarkdownTextSelectionHandlers
    let menus: MarkdownMenus

    init(
        attributedText: NSAttributedString,
        viewAttachments: [MarkdownResult.TextAttachment: UIView] = [:],
        markdownOptions: MarkdownOptions = .init(),
        uniqueIdentifier: AnyHashable? = nil,
        streaming: Bool = false,
        hapticFadeIn: Bool = false,
        showsHorizontalScrollIndicator: Bool = false,
        horizontalScrollIndicatorInset: CGFloat = 0,
        isScrollEnabled: Bool = true,
        linkHandlers: MarkdownTextLinkHandlers = .default,
        selectionHandlers: MarkdownTextSelectionHandlers = .none,
        menus: MarkdownMenus = .none
    ) {
        self.attributedText = attributedText
        self.viewAttachments = viewAttachments
        self.markdownOptions = markdownOptions
        self.uniqueIdentifier = uniqueIdentifier
        self.streaming = streaming
        self.hapticFadeIn = hapticFadeIn
        self.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        self.horizontalScrollIndicatorInset = horizontalScrollIndicatorInset
        self.isScrollEnabled = isScrollEnabled
        self.linkHandlers = linkHandlers
        self.selectionHandlers = selectionHandlers
        self.menus = menus
    }

    // MARK: - Coordinator

    /// Coordinator for managing UIView lifecycle.
    /// Mirrors OpenAI's `OAIMarkdown.HorizontallyScrollingMarkdownTextBlock.Coordinator`.
    class Coordinator {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - triggerSelectAll

    /// Returns a copy of this view configured to trigger a select-all action.
    /// Mirrors OpenAI's `OAIMarkdown.HorizontallyScrollingMarkdownTextBlock.triggerSelectAll(_:)`.
    func triggerSelectAll(_ id: AnyHashable?) -> HorizontallyScrollingMarkdownTextBlock {
        // Stub — returns self unchanged for now
        return self
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> HorizontallyScrollingMarkdownTextView {
        let view = HorizontallyScrollingMarkdownTextView(frame: .zero)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
        return view
    }

    func updateUIView(_ view: HorizontallyScrollingMarkdownTextView, context: Context) {
        view.attributedText = attributedText
    }

    @MainActor
    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView view: HorizontallyScrollingMarkdownTextView,
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
