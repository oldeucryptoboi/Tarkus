import SwiftUI

// MARK: - MarkdownText

/// Convenience SwiftUI view for rendering a markdown string.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownText`.
///
/// Usage:
/// ```swift
/// MarkdownText(content: message.text)
/// ```
struct MarkdownText: View {

    private let content: String
    private let streaming: Bool
    private let initOptions: MarkdownOptions?

    @State private var result = MarkdownResult()
    @Environment(\.colorScheme) private var colorScheme

    /// Shared highlighter actor — created once, reused across recompositions.
    @State private var highlighter = MarkdownCodeBlockHighlighter(
        colorScheme: CodeHighlighterColorScheme(colorScheme: .dark)
    )

    /// Typing dot post-process state — appends a bullet indicator during streaming.
    @State private var typingDotState = TypingDotPostProcessState()

    init(content: String, streaming: Bool = false, options: MarkdownOptions? = nil) {
        self.content = content
        self.streaming = streaming
        self.initOptions = options
    }

    var body: some View {
        MarkdownBlockStack(
            content: result,
            markdownOptions: resolvedOptions,
            codeBlockHighlighter: highlighter
        )
        .task(id: "\(content.hashValue)-\(colorScheme)-\(streaming)") {
            let compiler = MarkdownCompiler()
            var compiled = compiler.result(from: content, options: resolvedOptions)
            typingDotState.postProcess(showsTypingDotWhenStreaming: streaming).perform(&compiled)
            result = compiled
        }
    }

    private var resolvedOptions: MarkdownOptions {
        initOptions ?? .chatMessage(colorScheme: colorScheme)
    }
}
