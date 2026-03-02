import Foundation
import Markdown

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - AttributedStringBuilder

/// Walks inline markup nodes and produces a styled `NSAttributedString`.
/// Internal to the compiler — handles bold, italic, code, links, etc.
struct AttributedStringBuilder: MarkupWalker {

    private let options: MarkdownOptions
    private var result = NSMutableAttributedString()
    private var traitStack = FontTraitStack()

    init(options: MarkdownOptions) {
        self.options = options
    }

    // MARK: - Public

    static func build(from markup: Markup, options: MarkdownOptions) -> NSAttributedString {
        var builder = AttributedStringBuilder(options: options)
        markup.accept(&builder)
        return builder.result
    }

    static func build(from children: MarkupChildren, options: MarkdownOptions) -> NSAttributedString {
        var builder = AttributedStringBuilder(options: options)
        for child in children {
            child.accept(&builder)
        }
        return builder.result
    }

    // MARK: - Inline Visitors

    mutating func visitText(_ text: Markdown.Text) {
        append(text.string)
    }

    mutating func visitStrong(_ strong: Strong) {
        traitStack.push(.bold)
        descendInto(strong)
        traitStack.pop()
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        traitStack.push(.italic)
        descendInto(emphasis)
        traitStack.pop()
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) {
        let start = result.length
        descendInto(strikethrough)
        let range = NSRange(location: start, length: result.length - start)
        result.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: range)
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: options.textStyle.monospacedFont(),
            .foregroundColor: options.codeInlineTextColor,
            .backgroundColor: options.codeInlineBackground,
        ]
        result.append(NSAttributedString(string: inlineCode.code, attributes: attrs))
    }

    mutating func visitLink(_ link: Markdown.Link) {
        let start = result.length
        descendInto(link)
        let range = NSRange(location: start, length: result.length - start)
        if let destination = link.destination, let url = URL(string: destination) {
            result.addAttribute(.link, value: url, range: range)
        }
        if let linkColor = options.linkColor {
            result.addAttribute(.foregroundColor, value: linkColor, range: range)
        }
        if let underlineStyle = options.linkUnderlineStyle {
            result.addAttribute(.underlineStyle, value: underlineStyle.rawValue, range: range)
        }
    }

    mutating func visitImage(_ image: Markdown.Image) {
        let altText = image.plainText.isEmpty ? "image" : image.plainText
        append("[\(altText)]")
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) {
        append(" ")
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) {
        append("\n")
    }

    // MARK: - Private

    private mutating func append(_ string: String) {
        let font = resolveFont()
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = options.lineHeightMultiple

        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
        ]
        if let textColor = options.textColor {
            attrs[.foregroundColor] = textColor
        }
        result.append(NSAttributedString(string: string, attributes: attrs))
    }

    private func resolveFont() -> PlatformFont {
        let traits = traitStack.current
        if traits.contains(.bold) && traits.contains(.italic) {
            return options.textStyle.boldItalicFont()
        } else if traits.contains(.bold) {
            return options.textStyle.boldFont()
        } else if traits.contains(.italic) {
            return options.textStyle.italicFont()
        }
        return options.textStyle.platformAgnosticFont()
    }

    private mutating func descendInto(_ markup: Markup) {
        for child in markup.children {
            child.accept(&self)
        }
    }
}

// MARK: - FontTraitStack

/// Tracks nested bold/italic state for correct font composition.
private struct FontTraitStack {

    enum Trait { case bold, italic }

    private var stack: [Trait] = []

    var current: Set<Trait> { Set(stack) }

    mutating func push(_ trait: Trait) { stack.append(trait) }
    mutating func pop() { _ = stack.popLast() }
}
