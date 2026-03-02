import SwiftUI

// MARK: - ToolSessionStyle

/// Styling for tool session cards.
/// Mirrors OpenAI's `OAIMarkdown.ToolSessionStyle`.
struct ToolSessionStyle: Equatable {

    static var defaultInProgressForegroundColor: Color { .blue }
    static var defaultShimmerColor: Color { .white.opacity(0.3) }
    static var defaultShimmerUpdateInterval: Duration { .seconds(1) }

    var markdownOptions: MarkdownOptions
    var inProgressFontWeight: Font.Weight
    var normalFontWeight: Font.Weight
    var detailFontWeight: Font.Weight
    var expandIconSize: CGFloat
    var expandIconColor: Color
    var inProgressForegroundColor: Color
    var normalForegroundColor: Color
    var shimmerColor: Color
    var shimmerUpdateInterval: Duration
    var detailColor: Color

    init(
        markdownOptions: MarkdownOptions,
        inProgressFontWeight: Font.Weight = .medium,
        normalFontWeight: Font.Weight = .regular,
        detailFontWeight: Font.Weight = .regular,
        expandIconSize: CGFloat = 12,
        expandIconColor: Color = .secondary,
        inProgressForegroundColor: Color = defaultInProgressForegroundColor,
        normalForegroundColor: Color = .primary,
        shimmerColor: Color = defaultShimmerColor,
        shimmerUpdateInterval: Duration = defaultShimmerUpdateInterval,
        detailColor: Color = .secondary
    ) {
        self.markdownOptions = markdownOptions
        self.inProgressFontWeight = inProgressFontWeight
        self.normalFontWeight = normalFontWeight
        self.detailFontWeight = detailFontWeight
        self.expandIconSize = expandIconSize
        self.expandIconColor = expandIconColor
        self.inProgressForegroundColor = inProgressForegroundColor
        self.normalForegroundColor = normalForegroundColor
        self.shimmerColor = shimmerColor
        self.shimmerUpdateInterval = shimmerUpdateInterval
        self.detailColor = detailColor
    }

    // MARK: - Equatable

    static func == (lhs: ToolSessionStyle, rhs: ToolSessionStyle) -> Bool {
        lhs.markdownOptions == rhs.markdownOptions
            && lhs.inProgressFontWeight == rhs.inProgressFontWeight
            && lhs.normalFontWeight == rhs.normalFontWeight
            && lhs.detailFontWeight == rhs.detailFontWeight
            && lhs.expandIconSize == rhs.expandIconSize
            && lhs.expandIconColor == rhs.expandIconColor
            && lhs.inProgressForegroundColor == rhs.inProgressForegroundColor
            && lhs.normalForegroundColor == rhs.normalForegroundColor
            && lhs.shimmerColor == rhs.shimmerColor
            && lhs.shimmerUpdateInterval == rhs.shimmerUpdateInterval
            && lhs.detailColor == rhs.detailColor
    }
}
