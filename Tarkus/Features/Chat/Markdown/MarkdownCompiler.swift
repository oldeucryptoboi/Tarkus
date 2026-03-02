import Foundation
import Markdown

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MarkdownCompiler

/// Transforms a markdown string into a `MarkdownResult`.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownCompiler`.
///
/// Pipeline:
/// 1. Each plugin preprocesses the raw markdown string
/// 2. `swift-markdown` (cmark-gfm) parses to AST
/// 3. Compiler walks AST, producing `MarkdownResult.Item` array
/// 4. Each plugin post-processes the result
struct MarkdownCompiler {

    private let plugins: [MarkdownPlugin]
    private let customLinkParsers: [MarkdownLinkParser]
    private let traitCollection: PlatformAppearance

    init(
        plugins: [MarkdownPlugin] = [],
        customLinkParsers: [MarkdownLinkParser] = [],
        traitCollection: PlatformAppearance = MarkdownCompiler.defaultAppearance
    ) {
        self.plugins = plugins
        self.customLinkParsers = customLinkParsers
        self.traitCollection = traitCollection
    }

    // MARK: - Public API

    /// Compile a markdown string into a `MarkdownResult`.
    /// Mirrors OpenAI's `compiler.result(from:options:appliesSourcePositionAttributes:)`.
    func result(
        from markdown: String,
        options: MarkdownOptions = .init(),
        appliesSourcePositionAttributes: Bool = false
    ) -> MarkdownResult {
        // Phase 1: Plugin preprocessing
        var processedMarkdown = markdown
        for plugin in plugins {
            plugin.preprocess(markdown: &processedMarkdown)
        }

        // Phase 2: Parse and walk AST
        let document = Document(parsing: processedMarkdown)
        var walker = ASTWalker(options: options)
        document.accept(&walker)

        // Phase 3: Plugin postprocessing
        var result = MarkdownResult(items: walker.items)
        for plugin in plugins {
            plugin.postProcess(result: &result, options: options, traitCollection: traitCollection)
        }

        return result
    }

    /// Convert a markdown string to HTML.
    /// Mirrors OpenAI's `MarkdownCompiler.html(fromMarkdown:)`.
    func html(fromMarkdown markdown: String) -> String {
        // Stub — returns empty string for now
        return ""
    }

    // MARK: - Default Appearance

    private static var defaultAppearance: PlatformAppearance {
        #if canImport(AppKit)
        return NSAppearance.current ?? NSAppearance(named: .aqua)!
        #else
        return UITraitCollection.current
        #endif
    }
}

// MARK: - ASTWalker

/// Internal MarkupWalker that converts the AST into `MarkdownResult.Item` array.
private struct ASTWalker: MarkupWalker {

    let options: MarkdownOptions
    var items: [MarkdownResult.Item] = []

    /// Resolved text color (since options.textColor is now optional).
    private var textColor: PlatformColor {
        options.textColor ?? .platformLabel
    }

    // MARK: - Block Visitors

    mutating func visitParagraph(_ paragraph: Paragraph) {
        let attributed = AttributedStringBuilder.build(from: paragraph.children, options: options)
        items.append(.text(.init(text: attributed)))
    }

    mutating func visitHeading(_ heading: Heading) {
        let level = heading.level
        let attributed = buildHeadingString(heading)
        items.append(.text(.init(text: attributed, headingLevel: level)))
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) {
        let language = codeBlock.language?.trimmingCharacters(in: .whitespaces)
        let code = codeBlock.code.hasSuffix("\n")
            ? String(codeBlock.code.dropLast())
            : codeBlock.code
        items.append(.code(.init(code: code, language: language)))
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) {
        // Compile blockquote children into inner items.
        var inner = ASTWalker(options: options)
        for child in blockQuote.children {
            child.accept(&inner)
        }

        // Merge inner text items with blockquote styling (secondary color).
        // The left accent bar is rendered by MarkdownBlockStack, not via indentation.
        let merged = NSMutableAttributedString()
        for (i, item) in inner.items.enumerated() {
            if i > 0 { merged.append(NSAttributedString(string: "\n")) }
            switch item {
            case .text(let t):
                merged.append(t.text)
            case .code(let c):
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: options.codeTextStyle.monospacedFont(),
                    .foregroundColor: textColor,
                ]
                merged.append(NSAttributedString(string: c.code, attributes: attrs))
            case .table:
                items.append(item)
            case .images:
                items.append(item)
            }
        }

        if merged.length > 0 {
            let fullRange = NSRange(location: 0, length: merged.length)
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = options.lineHeightMultiple
            merged.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)

            items.append(.text(.init(text: merged, isBlockquote: true)))
        }
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) {
        let startIndex = Int(orderedList.startIndex)
        let listItems = Array(orderedList.listItems)
        let attributed = buildListString(items: listItems, ordered: true, startIndex: startIndex, depth: 0)
        items.append(.text(.init(text: attributed)))
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) {
        let listItems = Array(unorderedList.listItems)
        let attributed = buildListString(items: listItems, ordered: false, startIndex: 1, depth: 0)
        items.append(.text(.init(text: attributed)))
    }

    mutating func visitTable(_ table: Table) {
        // Note: column alignments are no longer stored on MarkdownTable (OAI doesn't have them).
        // We store them as sourcePosition metadata for now if needed.
        let headerCells = Array(table.head.cells).map { cell in
            MarkdownTable.Cell(text: AttributedStringBuilder.build(from: cell.children, options: options))
        }

        let bodyRows = Array(table.body.rows).map { row in
            MarkdownTable.Row(cells: Array(row.cells).map { cell in
                MarkdownTable.Cell(text: AttributedStringBuilder.build(from: cell.children, options: options))
            })
        }

        let mdTable = MarkdownTable(
            head: .init(cells: headerCells),
            body: .init(rows: bodyRows)
        )
        items.append(.table(mdTable))
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) {
        // Horizontal rules are rendered as empty text items with a special marker
        let attrs: [NSAttributedString.Key: Any] = [
            .font: options.textStyle.platformAgnosticFont(),
            .foregroundColor: PlatformColor.clear,
        ]
        let hrText = NSAttributedString(string: "---", attributes: attrs)
        items.append(.text(.init(text: hrText, headingLevel: -1)))  // -1 = horizontal rule marker
    }

    mutating func visitHTMLBlock(_ html: HTMLBlock) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: options.textStyle.platformAgnosticFont(),
            .foregroundColor: textColor,
        ]
        let attributed = NSAttributedString(string: html.rawHTML, attributes: attrs)
        items.append(.text(.init(text: attributed)))
    }

    // MARK: - List Building

    /// Builds a single NSAttributedString for an entire list using paragraph styling
    /// with tab stops for proper indentation — matching how OAI handles lists as text items.
    private func buildListString(items: [ListItem], ordered: Bool, startIndex: Int, depth: Int) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let indent: CGFloat = CGFloat(depth) * 20 + 20

        for (index, item) in items.enumerated() {
            if result.length > 0 {
                result.append(NSAttributedString(string: "\n"))
            }

            // Bullet or number prefix
            let prefix: String
            if ordered {
                prefix = "\(startIndex + index). "
            } else {
                let bullets = ["\u{2022}", "\u{25E6}", "\u{25AA}"]  // bullet, circle, square
                prefix = "\(bullets[min(depth, bullets.count - 1)]) "
            }

            // Paragraph style with indentation
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.headIndent = indent
            paragraphStyle.firstLineHeadIndent = indent - 16
            paragraphStyle.lineHeightMultiple = options.lineHeightMultiple
            paragraphStyle.paragraphSpacing = options.listInterItemSpacing

            // Build the list item text
            let prefixAttrs: [NSAttributedString.Key: Any] = [
                .font: options.textStyle.platformAgnosticFont(),
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle,
            ]
            result.append(NSAttributedString(string: prefix, attributes: prefixAttrs))

            // Compile paragraph children
            for child in item.children {
                if let paragraph = child as? Paragraph {
                    let built = AttributedStringBuilder.build(from: paragraph.children, options: options)
                    let mutable = NSMutableAttributedString(attributedString: built)
                    let range = NSRange(location: 0, length: mutable.length)
                    mutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
                    result.append(mutable)
                } else if let nestedOrdered = child as? OrderedList {
                    let nestedItems = Array(nestedOrdered.listItems)
                    let nested = buildListString(
                        items: nestedItems, ordered: true,
                        startIndex: Int(nestedOrdered.startIndex), depth: depth + 1
                    )
                    result.append(NSAttributedString(string: "\n"))
                    result.append(nested)
                } else if let nestedUnordered = child as? UnorderedList {
                    let nestedItems = Array(nestedUnordered.listItems)
                    let nested = buildListString(
                        items: nestedItems, ordered: false,
                        startIndex: 1, depth: depth + 1
                    )
                    result.append(NSAttributedString(string: "\n"))
                    result.append(nested)
                }
            }
        }

        return result
    }

    // MARK: - Heading Building

    private func buildHeadingString(_ heading: Heading) -> NSAttributedString {
        let level = min(heading.level, 6)
        let headingStyle = options.headingTextStyle(level: level)
        let result = NSMutableAttributedString()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.1

        for child in heading.children {
            if let text = child as? Markdown.Text {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: headingStyle.boldFont(),
                    .foregroundColor: textColor,
                    .paragraphStyle: paragraphStyle,
                ]
                result.append(NSAttributedString(string: text.string, attributes: attrs))
            } else if let code = child as? InlineCode {
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: headingStyle.monospacedFont(),
                    .foregroundColor: options.codeInlineTextColor,
                    .backgroundColor: options.codeInlineBackground,
                    .paragraphStyle: paragraphStyle,
                ]
                result.append(NSAttributedString(string: code.code, attributes: attrs))
            } else {
                // Other inline elements — build with standard builder, override font
                let built = AttributedStringBuilder.build(from: child, options: options)
                let mutable = NSMutableAttributedString(attributedString: built)
                let range = NSRange(location: 0, length: mutable.length)
                mutable.addAttribute(.font, value: headingStyle.boldFont(), range: range)
                mutable.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
                result.append(mutable)
            }
        }

        return result
    }
}

// MARK: - PlatformColor Extension

private extension PlatformColor {
    static var secondaryLabel: PlatformColor {
        #if canImport(AppKit)
        return .secondaryLabelColor
        #else
        return .secondaryLabel
        #endif
    }

    static var platformLabel: PlatformColor {
        #if canImport(AppKit)
        return NSColor.labelColor
        #else
        return UIColor.label
        #endif
    }
}
