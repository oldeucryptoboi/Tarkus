import SwiftUI

#if canImport(AppKit)
import AppKit
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
typealias PlatformFontDescriptorSymbolicTraits = NSFontDescriptor.SymbolicTraits
typealias PlatformAppearance = NSAppearance
typealias PlatformFontWeight = NSFont.Weight
typealias PlatformImage = NSImage
#else
import UIKit
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
typealias PlatformFontDescriptorSymbolicTraits = UIFontDescriptor.SymbolicTraits
typealias PlatformAppearance = UITraitCollection
typealias PlatformFontWeight = UIFont.Weight
typealias PlatformImage = UIImage
#endif

// MARK: - MarkdownOptions

/// Styling and configuration for markdown rendering.
/// Matches OpenAI's `OAIMarkdown.MarkdownOptions` interface exactly.
struct MarkdownOptions: Equatable {

    // MARK: - Nested Types

    /// Describes a text style that computes fonts lazily from platform text style + size.
    /// Matches OAI's `MarkdownOptions.TextStyle`.
    struct TextStyle: Equatable {
        var platformTextStyle: PlatformFont.TextStyle
        var size: CGFloat?
        var alwaysConsiderSizeDelta: Bool

        init(
            textStyle: PlatformFont.TextStyle = .body,
            size: CGFloat? = nil,
            alwaysConsiderSizeDelta: Bool = false
        ) {
            self.platformTextStyle = textStyle
            self.size = size
            self.alwaysConsiderSizeDelta = alwaysConsiderSizeDelta
        }

        // MARK: Computed Fonts (matching OAI's lazy approach)

        func monospacedFont(traitCollection: PlatformAppearance? = nil, with fontSizeSetting: FontSizeSetting = .default) -> PlatformFont {
            let resolvedSize = resolveSize(with: fontSizeSetting)
            return PlatformFont.monospacedSystemFont(ofSize: resolvedSize, weight: .regular)
        }

        func monospacedNumbersFont(traitCollection: PlatformAppearance? = nil, with fontSizeSetting: FontSizeSetting = .default) -> PlatformFont {
            let resolvedSize = resolveSize(with: fontSizeSetting)
            return PlatformFont.monospacedDigitSystemFont(ofSize: resolvedSize, weight: .regular)
        }

        func platformAgnosticFont(traitCollection: PlatformAppearance? = nil, with fontSizeSetting: FontSizeSetting = .default) -> PlatformFont {
            let resolvedSize = resolveSize(with: fontSizeSetting)
            return PlatformFont.systemFont(ofSize: resolvedSize)
        }

        func font(with fontSizeSetting: FontSizeSetting = .default) -> Font {
            let resolvedSize = resolveSize(with: fontSizeSetting)
            return .system(size: resolvedSize)
        }

        func boldFont(with fontSizeSetting: FontSizeSetting = .default) -> PlatformFont {
            let resolvedSize = resolveSize(with: fontSizeSetting)
            return PlatformFont.boldSystemFont(ofSize: resolvedSize)
        }

        func italicFont(with fontSizeSetting: FontSizeSetting = .default) -> PlatformFont {
            let resolvedSize = resolveSize(with: fontSizeSetting)
            let body = PlatformFont.systemFont(ofSize: resolvedSize)
            #if canImport(AppKit)
            let desc = body.fontDescriptor.withSymbolicTraits(.italic)
            return NSFont(descriptor: desc, size: resolvedSize) ?? body
            #else
            let desc = body.fontDescriptor.withSymbolicTraits(.traitItalic)
            return UIFont(descriptor: desc ?? body.fontDescriptor, size: resolvedSize)
            #endif
        }

        func boldItalicFont(with fontSizeSetting: FontSizeSetting = .default) -> PlatformFont {
            let resolvedSize = resolveSize(with: fontSizeSetting)
            let bold = PlatformFont.boldSystemFont(ofSize: resolvedSize)
            #if canImport(AppKit)
            let desc = bold.fontDescriptor.withSymbolicTraits([.bold, .italic])
            return NSFont(descriptor: desc, size: resolvedSize) ?? bold
            #else
            let desc = bold.fontDescriptor.withSymbolicTraits([.traitBold, .traitItalic])
            return UIFont(descriptor: desc ?? bold.fontDescriptor, size: resolvedSize)
            #endif
        }

        // MARK: Heading Factory

        static func heading(size: CGFloat) -> TextStyle {
            TextStyle(textStyle: .headline, size: size, alwaysConsiderSizeDelta: false)
        }

        // MARK: Private

        private func resolveSize(with fontSizeSetting: FontSizeSetting) -> CGFloat {
            let base = size ?? defaultSize(for: platformTextStyle)
            return base + (alwaysConsiderSizeDelta ? fontSizeSetting.sizeDelta : 0)
        }

        private func defaultSize(for textStyle: PlatformFont.TextStyle) -> CGFloat {
            #if canImport(AppKit)
            switch textStyle {
            case .headline: return 17
            case .subheadline: return 15
            case .caption1, .caption2: return 12
            default: return 14
            }
            #else
            switch textStyle {
            case .headline: return 17
            case .subheadline: return 15
            case .caption1, .caption2: return 12
            default: return 14
            }
            #endif
        }
    }

    /// Matches OAI's `MarkdownOptions.TextStyleKind`.
    enum TextStyleKind: Hashable {
        case body
        case code
        case table
        case footnote
    }

    /// Matches OAI's `MarkdownOptions.FontSizeSetting`.
    enum FontSizeSetting: Int, RawRepresentable, Hashable, CaseIterable {
        case smallest = -2
        case smaller = -1
        case normal = 0
        case larger = 1
        case largest = 2

        static var `default`: FontSizeSetting { .normal }

        var sizeDelta: CGFloat {
            CGFloat(rawValue) * 2.0
        }

        var higher: FontSizeSetting {
            FontSizeSetting(rawValue: rawValue + 1) ?? .largest
        }

        var lower: FontSizeSetting {
            FontSizeSetting(rawValue: rawValue - 1) ?? .smallest
        }

        var isHighest: Bool { self == .largest }
        var isLowest: Bool { self == .smallest }

        mutating func increase() { self = higher }
        mutating func decrease() { self = lower }
    }

    /// Matches OAI's `MarkdownOptions.AttributeContext`.
    struct AttributeContext: Equatable {
        var linkEnvironment: LinkEnvironment
        var isInsideTable: Bool

        static var initial: AttributeContext {
            AttributeContext(linkEnvironment: LinkEnvironment(), isInsideTable: false)
        }

        struct TextEnvironment: Equatable {}
        struct LinkEnvironment: Equatable {}
    }

    // MARK: - Text Styling

    var textStyle: TextStyle
    var tableTextStyle: TextStyle
    var codeTextStyle: TextStyle
    var footnoteTextStyle: TextStyle

    var kern: CGFloat?
    var lineBreakMode: NSLineBreakMode
    var lineHeightMultiple: CGFloat

    var textColor: PlatformColor?
    var strongTextColor: PlatformColor?
    var strongTextWeight: PlatformFontWeight
    var textInsets: NSDirectionalEdgeInsets
    var textPadding: EdgeInsets
    var textContainerInset: CGSize
    var textBoundingSizeAdjustment: CGSize

    // MARK: - Link Styling

    var linkColor: PlatformColor?
    var linkUnderlineStyle: NSUnderlineStyle?
    var linkUnderlineColor: PlatformColor?
    var linkTrailingAttachment: PlatformImage?

    // MARK: - Layout

    var insets: NSDirectionalEdgeInsets
    var interContentSpacing: CGFloat

    // MARK: - Tables

    var tableCellInsets: NSDirectionalEdgeInsets
    var tableBorderCornerRadius: CGFloat
    var tableHeaderBackgroundColor: PlatformColor
    var tableInterContentSpacing: CGFloat

    // MARK: - Images

    var imageCornerRadius: CGFloat?
    var gridImageCornerRadius: CGFloat?
    var maxImageWidth: CGFloat?
    var maxImageHeight: CGFloat?
    var maxImageGridWidth: CGFloat?
    var imageGridSpacing: CGFloat
    var showImageIndexBadge: Bool
    var maxImagesPerGridRowCompact: Int
    var maxImagesPerGridRowRegular: Int
    var showSingleImageShareButton: Bool
    var singleImageShareButtonInsets: EdgeInsets

    // MARK: - Code Block

    var codeHeaderInsets: NSDirectionalEdgeInsets
    var codeBlockBackground: PlatformColor?
    var codeInsets: NSDirectionalEdgeInsets
    var codeTextContainerInset: CGSize
    var codeCornerRadius: CGFloat?

    // MARK: - Lists

    var listInterItemSpacing: CGFloat
    var indentFirstUnorderedListLevel: Bool
    var whitespaceAfterUnorderedListIcon: String?

    // MARK: - Horizontal Rule

    var horizontalRuleColor: Color
    var horizontalRuleInsets: NSDirectionalEdgeInsets
    var horizontalRuleHeight: CGFloat

    // MARK: - Block Quote

    var blockQuoteBarColor: Color
    var blockQuoteBarWidth: CGFloat
    var blockQuoteIndentation: CGFloat

    // MARK: - Tarkus Extensions (not in OAI)

    /// Inline code background color. Tarkus extension — OAI handles this differently.
    var codeInlineBackground: PlatformColor
    /// Inline code text color. Tarkus extension — OAI handles this differently.
    var codeInlineTextColor: PlatformColor
    /// Table stripe background. Tarkus extension.
    var tableStripeBackgroundColor: PlatformColor
    /// Table border color. Tarkus extension.
    var tableBorderColor: PlatformColor
    /// Highlightr theme name. Tarkus extension — OAI uses HighlightrCodeHighlighter.Theme enum.
    var highlightrThemeName: String

    // MARK: - Computed Properties

    var edgeInsets: EdgeInsets {
        EdgeInsets(
            top: insets.top,
            leading: insets.leading,
            bottom: insets.bottom,
            trailing: insets.trailing
        )
    }

    var newReasoningMarkdownOptions: MarkdownOptions {
        var copy = self
        copy.lineHeightMultiple = 1.2
        return copy
    }

    // MARK: - Init

    /// Default init — dark mode chat message options.
    init() {
        let isDark = true
        let bodySize: CGFloat = 14
        let codeSize: CGFloat = 13

        self.textStyle = TextStyle(textStyle: .body, size: bodySize)
        self.tableTextStyle = TextStyle(textStyle: .body, size: bodySize - 1)
        self.codeTextStyle = TextStyle(textStyle: .body, size: codeSize)
        self.footnoteTextStyle = TextStyle(textStyle: .caption1, size: 11)
        self.kern = nil
        self.lineBreakMode = .byWordWrapping
        self.lineHeightMultiple = 1.3
        self.textColor = isDark ? .white : .black
        self.strongTextColor = nil
        self.strongTextWeight = .bold
        self.textInsets = NSDirectionalEdgeInsets()
        self.textPadding = .init()
        self.textContainerInset = .zero
        self.textBoundingSizeAdjustment = .zero
        self.linkColor = PlatformColor(red: 0.45, green: 0.65, blue: 1.0, alpha: 1.0)
        self.linkUnderlineStyle = .single
        self.linkUnderlineColor = nil
        self.linkTrailingAttachment = nil
        self.insets = NSDirectionalEdgeInsets()
        self.interContentSpacing = 12
        self.tableCellInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        self.tableBorderCornerRadius = 6
        self.tableHeaderBackgroundColor = PlatformColor(white: 0.15, alpha: 1.0)
        self.tableInterContentSpacing = 0
        self.imageCornerRadius = 8
        self.gridImageCornerRadius = 8
        self.maxImageWidth = nil
        self.maxImageHeight = nil
        self.maxImageGridWidth = nil
        self.imageGridSpacing = 4
        self.showImageIndexBadge = false
        self.maxImagesPerGridRowCompact = 2
        self.maxImagesPerGridRowRegular = 3
        self.showSingleImageShareButton = false
        self.singleImageShareButtonInsets = .init()
        self.codeHeaderInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        self.codeBlockBackground = PlatformColor(white: 0.12, alpha: 1.0)
        self.codeInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        self.codeTextContainerInset = .zero
        self.codeCornerRadius = 8
        self.listInterItemSpacing = 4
        self.indentFirstUnorderedListLevel = true
        self.whitespaceAfterUnorderedListIcon = nil
        self.horizontalRuleColor = Color(white: 0.3)
        self.horizontalRuleInsets = NSDirectionalEdgeInsets()
        self.horizontalRuleHeight = 1
        self.blockQuoteBarColor = Color(white: 0.55)
        self.blockQuoteBarWidth = 3
        self.blockQuoteIndentation = 16
        self.codeInlineBackground = PlatformColor(white: 1.0, alpha: 0.08)
        self.codeInlineTextColor = PlatformColor(red: 0.85, green: 0.85, blue: 0.88, alpha: 1.0)
        self.tableStripeBackgroundColor = PlatformColor(white: 0.1, alpha: 1.0)
        self.tableBorderColor = PlatformColor(white: 0.3, alpha: 1.0)
        self.highlightrThemeName = "xcode-dark"
    }

    // MARK: - Methods

    func textStyle(of kind: TextStyleKind) -> TextStyle {
        switch kind {
        case .body: return textStyle
        case .code: return codeTextStyle
        case .table: return tableTextStyle
        case .footnote: return footnoteTextStyle
        }
    }

    func applyingCodeOptionsToText() -> MarkdownOptions {
        var copy = self
        copy.textStyle = codeTextStyle
        return copy
    }

    func defaultAttributes(
        isRightToLeft: Bool = false,
        traitCollection: PlatformAppearance? = nil,
        attributeContext: AttributeContext = .initial,
        additionalTraits: PlatformFontDescriptorSymbolicTraits = []
    ) -> [NSAttributedString.Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        paragraphStyle.lineBreakMode = lineBreakMode
        if isRightToLeft {
            paragraphStyle.baseWritingDirection = .rightToLeft
        }

        var attrs: [NSAttributedString.Key: Any] = [
            .font: textStyle.platformAgnosticFont(traitCollection: traitCollection),
            .paragraphStyle: paragraphStyle,
        ]

        if let textColor {
            attrs[.foregroundColor] = textColor
        }

        if let kern {
            attrs[.kern] = kern
        }

        return attrs
    }

    static func formatTableHeaderItem(_ item: MarkdownResult.Item) -> MarkdownResult.Item {
        // Format table header cells with bold styling
        item
    }

    // MARK: - Heading Fonts

    static let headingSizes: [CGFloat] = [26, 22, 18, 16, 14, 13]

    func headingTextStyle(level: Int) -> TextStyle {
        let index = min(max(level - 1, 0), Self.headingSizes.count - 1)
        return .heading(size: Self.headingSizes[index])
    }

    // MARK: - Factory

    /// Creates options configured for a chat message response.
    /// Mirrors OpenAI's markdown options for chat messages.
    static func chatMessage(colorScheme: ColorScheme) -> MarkdownOptions {
        let isDark = colorScheme == .dark
        let bodySize: CGFloat = 14
        let codeSize: CGFloat = 13

        var opts = MarkdownOptions()
        opts.textStyle = TextStyle(textStyle: .body, size: bodySize)
        opts.tableTextStyle = TextStyle(textStyle: .body, size: bodySize - 1)
        opts.codeTextStyle = TextStyle(textStyle: .body, size: codeSize)
        opts.footnoteTextStyle = TextStyle(textStyle: .caption1, size: 11)
        opts.kern = nil
        opts.lineBreakMode = .byWordWrapping
        opts.lineHeightMultiple = 1.3
        opts.textColor = isDark ? .white : .black
        opts.strongTextColor = nil
        opts.strongTextWeight = .bold
        opts.textInsets = NSDirectionalEdgeInsets()
        opts.textPadding = .init()
        opts.textContainerInset = .zero
        opts.textBoundingSizeAdjustment = .zero
        opts.linkColor = isDark
            ? PlatformColor(red: 0.45, green: 0.65, blue: 1.0, alpha: 1.0)
            : .systemBlue
        opts.linkUnderlineStyle = .single
        opts.linkUnderlineColor = nil
        opts.linkTrailingAttachment = nil
        opts.insets = NSDirectionalEdgeInsets()
        opts.interContentSpacing = 12
        opts.tableCellInsets = NSDirectionalEdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
        opts.tableBorderCornerRadius = 6
        opts.tableHeaderBackgroundColor = isDark
            ? PlatformColor(white: 0.15, alpha: 1.0)
            : PlatformColor(white: 0.94, alpha: 1.0)
        opts.tableInterContentSpacing = 0
        opts.imageCornerRadius = 8
        opts.gridImageCornerRadius = 8
        opts.maxImageWidth = nil
        opts.maxImageHeight = nil
        opts.maxImageGridWidth = nil
        opts.imageGridSpacing = 4
        opts.showImageIndexBadge = false
        opts.maxImagesPerGridRowCompact = 2
        opts.maxImagesPerGridRowRegular = 3
        opts.showSingleImageShareButton = false
        opts.singleImageShareButtonInsets = .init()
        opts.codeHeaderInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        opts.codeBlockBackground = isDark
            ? PlatformColor(white: 0.12, alpha: 1.0)
            : PlatformColor(white: 0.96, alpha: 1.0)
        opts.codeInsets = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
        opts.codeTextContainerInset = .zero
        opts.codeCornerRadius = 8
        opts.listInterItemSpacing = 4
        opts.indentFirstUnorderedListLevel = true
        opts.whitespaceAfterUnorderedListIcon = nil
        opts.horizontalRuleColor = isDark
            ? Color(white: 0.3)
            : Color(white: 0.8)
        opts.horizontalRuleInsets = NSDirectionalEdgeInsets()
        opts.horizontalRuleHeight = 1
        opts.blockQuoteBarColor = isDark
            ? Color(white: 0.55)
            : Color(white: 0.65)
        opts.blockQuoteBarWidth = 3
        opts.blockQuoteIndentation = 16
        opts.codeInlineBackground = isDark
            ? PlatformColor(white: 1.0, alpha: 0.08)
            : PlatformColor(white: 0.0, alpha: 0.06)
        opts.codeInlineTextColor = isDark
            ? PlatformColor(red: 0.85, green: 0.85, blue: 0.88, alpha: 1.0)
            : PlatformColor(red: 0.20, green: 0.20, blue: 0.25, alpha: 1.0)
        opts.tableStripeBackgroundColor = isDark
            ? PlatformColor(white: 0.1, alpha: 1.0)
            : PlatformColor(white: 0.97, alpha: 1.0)
        opts.tableBorderColor = isDark
            ? PlatformColor(white: 0.3, alpha: 1.0)
            : PlatformColor(white: 0.82, alpha: 1.0)
        opts.highlightrThemeName = isDark ? "xcode-dark" : "xcode-light-custom"
        return opts
    }

    // MARK: - Equatable

    static func == (lhs: MarkdownOptions, rhs: MarkdownOptions) -> Bool {
        // Compare key rendering properties that affect layout
        lhs.lineHeightMultiple == rhs.lineHeightMultiple
            && lhs.interContentSpacing == rhs.interContentSpacing
            && lhs.highlightrThemeName == rhs.highlightrThemeName
            && lhs.textStyle == rhs.textStyle
            && lhs.codeTextStyle == rhs.codeTextStyle
            && lhs.tableTextStyle == rhs.tableTextStyle
    }
}
