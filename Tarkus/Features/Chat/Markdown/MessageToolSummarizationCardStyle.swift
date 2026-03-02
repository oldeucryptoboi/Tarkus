import SwiftUI

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MessageToolSummarizationCardStyle

/// Styling for message tool summarization cards.
/// Mirrors OpenAI's `OAIMarkdown.MessageToolSummarizationCardStyle`.
struct MessageToolSummarizationCardStyle {

    var markdownOptions: MarkdownOptions
    var opaque: Bool
    var insets: EdgeInsets
    var shape: Shape
    var detailsButton: Bool
    var titleButton: Bool
    var shimmeringTitle: Bool
    var horizontalSpacing: CGFloat
    var contentSpacing: CGFloat
    var intraElementSpacing: CGFloat
    var titleStyle: ItemStyle
    var subtitleStyle: ItemStyle
    var subtitleColor: PlatformColor
    var subtitleStreamingID: AnyHashable?
    var progressBarBackground: Color
    var shadow: Bool

    // MARK: - Shape

    struct Shape {
        static var `default`: Shape { Shape() }
    }

    // MARK: - ItemStyle

    struct ItemStyle {
        var textStyle: MarkdownOptions.TextStyle
        var weight: Font.Weight
        var lineLimit: Int?

        init(textStyle: MarkdownOptions.TextStyle, weight: Font.Weight = .regular, lineLimit: Int? = nil) {
            self.textStyle = textStyle
            self.weight = weight
            self.lineLimit = lineLimit
        }
    }

    // MARK: - Init

    init(
        markdownOptions: MarkdownOptions,
        opaque: Bool = false,
        insets: EdgeInsets? = nil,
        shape: Shape = .default,
        detailsButton: Bool = false,
        titleButton: Bool = false,
        shimmeringTitle: Bool = false,
        subtitleColor: PlatformColor = .secondaryLabelColor,
        subtitleStreamingID: AnyHashable? = nil,
        progressBarBackground: Color = .secondary.opacity(0.2),
        shadow: Bool = false
    ) {
        self.markdownOptions = markdownOptions
        self.opaque = opaque
        self.insets = insets ?? EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        self.shape = shape
        self.detailsButton = detailsButton
        self.titleButton = titleButton
        self.shimmeringTitle = shimmeringTitle
        self.horizontalSpacing = 8
        self.contentSpacing = 6
        self.intraElementSpacing = 4
        self.titleStyle = ItemStyle(
            textStyle: markdownOptions.textStyle,
            weight: .medium
        )
        self.subtitleStyle = ItemStyle(
            textStyle: MarkdownOptions.TextStyle(textStyle: .caption1, size: 12),
            weight: .regular
        )
        self.subtitleColor = subtitleColor
        self.subtitleStreamingID = subtitleStreamingID
        self.progressBarBackground = progressBarBackground
        self.shadow = shadow
    }
}
