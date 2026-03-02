import Foundation

// MARK: - LatexMarkdownPreprocessor

/// Mirrors OpenAI's `OAIMarkdown.LatexMarkdownPreprocessor`.
struct LatexMarkdownPreprocessor {
    var disableLatexEscapeAllPunctuation: Bool

    init(disableLatexEscapeAllPunctuation: Bool = false) {
        self.disableLatexEscapeAllPunctuation = disableLatexEscapeAllPunctuation
    }

    func preprocess(markdown: inout String) {
        // Stub — LaTeX preprocessing not implemented
    }
}
