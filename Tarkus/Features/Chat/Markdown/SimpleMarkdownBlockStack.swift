import SwiftUI

// MARK: - SimpleMarkdownBlockStack

/// A simplified markdown block stack view for rendering markdown content
/// without the full set of interaction handlers.
/// Mirrors OpenAI's `OAIMarkdown.SimpleMarkdownBlockStack`.
///
/// Use this when you need basic markdown rendering without link handlers,
/// selection handlers, image actions, etc.
struct SimpleMarkdownBlockStack: View {

    private let content: String
    private let options: MarkdownOptions
    private let streaming: Bool
    private let hugsTextHorizontally: Bool
    private let postProcess: MarkdownPostProcess?

    @State private var result = MarkdownResult()
    @State private var highlighter = MarkdownCodeBlockHighlighter(
        colorScheme: CodeHighlighterColorScheme(colorScheme: .dark)
    )

    init(
        content: String,
        options: MarkdownOptions,
        streaming: Bool = false,
        hugsTextHorizontally: Bool = false,
        postProcess: MarkdownPostProcess? = nil
    ) {
        self.content = content
        self.options = options
        self.streaming = streaming
        self.hugsTextHorizontally = hugsTextHorizontally
        self.postProcess = postProcess
    }

    var body: some View {
        MarkdownBlockStack(
            content: result,
            markdownOptions: options,
            codeBlockHighlighter: highlighter
        )
        .task(id: content) {
            let compiler = MarkdownCompiler()
            var compiled = compiler.result(from: content, options: options)
            if let postProcess = postProcess {
                postProcess.perform(&compiled)
            }
            result = compiled
        }
    }
}
