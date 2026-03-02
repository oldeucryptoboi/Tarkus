import SwiftUI

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MarkdownBlockStack

/// Renders a `MarkdownResult` as a vertical stack of block views.
/// This is the primary view for displaying compiled markdown content.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownBlockStack`.
struct MarkdownBlockStack: View {

    let content: MarkdownResult
    let markdownOptions: MarkdownOptions
    let transitionNamespace: Namespace.ID?
    let fadeAnimatorConfiguration: TextFadeAnimator.Configuration
    let uniqueIdentifierForItemAtIndex: (Int) -> AnyHashable?
    let streaming: Bool
    let hapticFadeIn: Bool
    let includeStickyCodeHeaders: Bool
    let postProcess: MarkdownPostProcess?
    let codeBlockHighlighter: MarkdownCodeBlockHighlighter?
    let insertions: [IdentifiableMarkdownReferencePath]
    let selectionHandler: (MarkdownSelection) -> ()
    let linkHandlers: MarkdownTextLinkHandlers
    let textSelectionHandlers: MarkdownTextSelectionHandlers
    let imageActions: MarkdownImageActions
    let menus: MarkdownMenus
    let contentWillResizeHandler: () -> ()
    let conversationID: String?
    let imageGenDownloadURLs: [URL]
    let imageGenerationRenderStyle: ImageGenerationRenderStyle
    let imagesPreferMediumSize: Bool
    let activeHighlightIDs: Set<String>
    let highlightFramesUpdatedHandler: (([String: CGRect], Int) -> ())?
    let nonTableMaxWidth: CGFloat?
    let textBlockLineLimit: Int
    let hugsTextHorizontally: Bool
    let entityDetectionEnabled: Bool

    init(
        content: MarkdownResult,
        markdownOptions: MarkdownOptions = .init(),
        transitionNamespace: Namespace.ID? = nil,
        fadeAnimatorConfiguration: TextFadeAnimator.Configuration = .init(),
        uniqueIdentifierForItemAtIndex: @escaping (Int) -> AnyHashable? = { _ in nil },
        streaming: Bool = false,
        hapticFadeIn: Bool = false,
        includeStickyCodeHeaders: Bool = false,
        postProcess: MarkdownPostProcess? = nil,
        codeBlockHighlighter: MarkdownCodeBlockHighlighter? = nil,
        insertions: [IdentifiableMarkdownReferencePath] = [],
        selectionHandler: @escaping (MarkdownSelection) -> () = { _ in },
        linkHandlers: MarkdownTextLinkHandlers = .default,
        textSelectionHandlers: MarkdownTextSelectionHandlers = .none,
        imageActions: MarkdownImageActions = .none,
        menus: MarkdownMenus = .none,
        contentWillResizeHandler: @escaping () -> () = {},
        conversationID: String? = nil,
        imageGenDownloadURLs: [URL] = [],
        imageGenerationRenderStyle: ImageGenerationRenderStyle = .standard,
        imagesPreferMediumSize: Bool = false,
        activeHighlightIDs: Set<String> = [],
        highlightFramesUpdatedHandler: (([String: CGRect], Int) -> ())? = nil,
        nonTableMaxWidth: CGFloat? = nil,
        textBlockLineLimit: Int = 0,
        hugsTextHorizontally: Bool = false,
        entityDetectionEnabled: Bool = false
    ) {
        self.content = content
        self.markdownOptions = markdownOptions
        self.transitionNamespace = transitionNamespace
        self.fadeAnimatorConfiguration = fadeAnimatorConfiguration
        self.uniqueIdentifierForItemAtIndex = uniqueIdentifierForItemAtIndex
        self.streaming = streaming
        self.hapticFadeIn = hapticFadeIn
        self.includeStickyCodeHeaders = includeStickyCodeHeaders
        self.postProcess = postProcess
        self.codeBlockHighlighter = codeBlockHighlighter
        self.insertions = insertions
        self.selectionHandler = selectionHandler
        self.linkHandlers = linkHandlers
        self.textSelectionHandlers = textSelectionHandlers
        self.imageActions = imageActions
        self.menus = menus
        self.contentWillResizeHandler = contentWillResizeHandler
        self.conversationID = conversationID
        self.imageGenDownloadURLs = imageGenDownloadURLs
        self.imageGenerationRenderStyle = imageGenerationRenderStyle
        self.imagesPreferMediumSize = imagesPreferMediumSize
        self.activeHighlightIDs = activeHighlightIDs
        self.highlightFramesUpdatedHandler = highlightFramesUpdatedHandler
        self.nonTableMaxWidth = nonTableMaxWidth
        self.textBlockLineLimit = textBlockLineLimit
        self.hugsTextHorizontally = hugsTextHorizontally
        self.entityDetectionEnabled = entityDetectionEnabled
    }

    var body: some View {
        VStack(alignment: .leading, spacing: markdownOptions.interContentSpacing) {
            // Item no longer conforms to Identifiable; use the internal `id` property via id: \.id
            ForEach(Array(content.items.enumerated()), id: \.element.id) { _, item in
                itemView(item)
            }
        }
    }

    // MARK: - Item Dispatch

    @ViewBuilder
    private func itemView(_ item: MarkdownResult.Item) -> some View {
        switch item {
        case .text(let text):
            textItemView(text)

        case .code(let code):
            MarkdownCodeBlock(
                code: code.code,
                language: code.language,
                markdownOptions: markdownOptions,
                highlighter: codeBlockHighlighter
            )

        case .table(let table):
            MarkdownTableBlockView(table: table, options: markdownOptions)

        case .images:
            // Image rendering not yet implemented — placeholder
            EmptyView()
        }
    }

    @ViewBuilder
    private func textItemView(_ text: MarkdownResult.Item.Text) -> some View {
        if let headingLevel = text.headingLevel {
            if headingLevel == -1 {
                // Special marker for horizontal rules
                MarkdownHorizontalRuleView(options: markdownOptions)
            } else {
                MarkdownTextBlock(attributedText: text.text)
                    .padding(.top, headingLevel <= 2 ? 8 : 4)
            }
        } else if text.isBlockquote {
            MarkdownTextBlock(attributedText: text.text)
                .padding(.leading, markdownOptions.blockQuoteBarWidth + markdownOptions.blockQuoteIndentation)
                .overlay(alignment: .leading) {
                    markdownOptions.blockQuoteBarColor
                        .frame(width: markdownOptions.blockQuoteBarWidth)
                        .clipShape(RoundedRectangle(cornerRadius: markdownOptions.blockQuoteBarWidth / 2))
                }
        } else {
            MarkdownTextBlock(attributedText: text.text)
        }
    }
}
