import SwiftUI

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MarkdownCodeBlock

/// Renders a fenced code block with syntax highlighting, a header bar
/// (language label + copy button), and horizontal scrolling.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownCodeBlock`.
struct MarkdownCodeBlock: View {

    let code: String
    let language: String?
    let markdownOptions: MarkdownOptions
    let uniqueIdentifier: AnyHashable?
    let streaming: Bool
    let hapticFadeIn: Bool
    let includeHeader: Bool
    let includeStickyHeader: Bool
    let showsHorizontalScrollIndicator: Bool
    let isScrollEnabled: Bool
    let highlighter: MarkdownCodeBlockHighlighter?
    let selectionHandlers: MarkdownTextSelectionHandlers
    let menus: MarkdownMenus

    @State private var highlighted: NSAttributedString?
    @State private var copied = false
    @Environment(\.colorScheme) private var colorScheme

    /// Lazy default highlighter — created only when no external highlighter is provided.
    @State private var defaultHighlighter = MarkdownCodeBlockHighlighter(
        colorScheme: CodeHighlighterColorScheme(colorScheme: .dark)
    )

    init(
        code: String,
        language: String? = nil,
        markdownOptions: MarkdownOptions = .init(),
        uniqueIdentifier: AnyHashable? = nil,
        streaming: Bool = false,
        hapticFadeIn: Bool = false,
        includeHeader: Bool = true,
        includeStickyHeader: Bool = false,
        showsHorizontalScrollIndicator: Bool = false,
        isScrollEnabled: Bool = true,
        highlighter: MarkdownCodeBlockHighlighter? = nil,
        selectionHandlers: MarkdownTextSelectionHandlers = .none,
        menus: MarkdownMenus = .none
    ) {
        self.code = code
        self.language = language
        self.markdownOptions = markdownOptions
        self.uniqueIdentifier = uniqueIdentifier
        self.streaming = streaming
        self.hapticFadeIn = hapticFadeIn
        self.includeHeader = includeHeader
        self.includeStickyHeader = includeStickyHeader
        self.showsHorizontalScrollIndicator = showsHorizontalScrollIndicator
        self.isScrollEnabled = isScrollEnabled
        self.highlighter = highlighter
        self.selectionHandlers = selectionHandlers
        self.menus = menus
    }

    /// The effective highlighter: external or default.
    private var effectiveHighlighter: MarkdownCodeBlockHighlighter {
        highlighter ?? defaultHighlighter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar — language label + copy button
            if includeHeader {
                codeHeader
            }

            // Syntax-highlighted code with horizontal scroll
            HorizontallyScrollingMarkdownTextBlock(
                attributedText: highlighted ?? fallbackAttributedString
            )
            .padding(EdgeInsets(
                top: markdownOptions.codeInsets.top,
                leading: markdownOptions.codeInsets.leading,
                bottom: markdownOptions.codeInsets.bottom,
                trailing: markdownOptions.codeInsets.trailing
            ))
        }
        .background(codeBlockBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: markdownOptions.codeCornerRadius ?? 8))
        .task(id: "\(code.hashValue)-\(colorScheme)") {
            await performHighlighting()
        }
    }

    // MARK: - Header

    private var codeHeader: some View {
        HStack {
            Text(displayLanguage)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                copyToClipboard()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        .font(.caption2)
                    Text(copied ? "Copied" : "Copy")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(EdgeInsets(
            top: markdownOptions.codeHeaderInsets.top,
            leading: markdownOptions.codeHeaderInsets.leading,
            bottom: markdownOptions.codeHeaderInsets.bottom,
            trailing: markdownOptions.codeHeaderInsets.trailing
        ))
        .background(codeBlockBackgroundColor.opacity(0.7))
    }

    // MARK: - Private

    private var codeBlockBackgroundColor: Color {
        if let bg = markdownOptions.codeBlockBackground {
            return Color(bg)
        }
        return colorScheme == .dark
            ? Color(white: 0.12)
            : Color(white: 0.96)
    }

    private var displayLanguage: String {
        guard let lang = language, !lang.isEmpty else { return "code" }
        return lang.lowercased()
    }

    private var fallbackAttributedString: NSAttributedString {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: markdownOptions.codeTextStyle.monospacedFont(),
        ]
        if let textColor = markdownOptions.textColor {
            attrs[.foregroundColor] = textColor
        }
        return NSAttributedString(string: code, attributes: attrs)
    }

    private func performHighlighting() async {
        let colorScheme = CodeHighlighterColorScheme(colorScheme: colorScheme)
        await effectiveHighlighter.updateColorScheme(colorScheme)

        if let result = await effectiveHighlighter.highlight(code: code, language: language) {
            highlighted = result
        }
    }

    private func copyToClipboard() {
        #if canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        #else
        UIPasteboard.general.string = code
        #endif

        withAnimation { copied = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { copied = false }
        }
    }
}
