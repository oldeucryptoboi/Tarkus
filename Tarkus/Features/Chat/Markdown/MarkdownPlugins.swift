import Foundation

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - GroupAdjacentImagesMarkdownPlugin

/// Mirrors OpenAI's `OAIMarkdown.GroupAdjacentImagesMarkdownPlugin`.
class GroupAdjacentImagesMarkdownPlugin: MarkdownPlugin {
    init() {}
    func preprocess(markdown: inout String) {}
    func postProcess(result: inout MarkdownResult, options: MarkdownOptions, traitCollection: PlatformAppearance) {}
}

// MARK: - ContextListPlugin

/// Mirrors OpenAI's `OAIMarkdown.ContextListPlugin`.
class ContextListPlugin: MarkdownPlugin {
    init() {}
    func preprocess(markdown: inout String) {}
    func postProcess(result: inout MarkdownResult, options: MarkdownOptions, traitCollection: PlatformAppearance) {}
}

// MARK: - HiveTranscriptPlugin

/// Mirrors OpenAI's `OAIMarkdown.HiveTranscriptPlugin`.
class HiveTranscriptPlugin: MarkdownPlugin {
    init() {}
    func preprocess(markdown: inout String) {}
    func postProcess(result: inout MarkdownResult, options: MarkdownOptions, traitCollection: PlatformAppearance) {}
}

// MARK: - LatexMarkdownPlugin

/// Mirrors OpenAI's `OAIMarkdown.LatexMarkdownPlugin`.
class LatexMarkdownPlugin: MarkdownPlugin {
    let attachmentViewCacheEnabled: Bool
    let disableLatexEscapeAllPunctuation: Bool
    let latexAnalyticsLogger: (@Sendable (LatexAnalyticsEvent) -> Void)?

    init(
        attachmentViewCacheEnabled: Bool = true,
        disableLatexEscapeAllPunctuation: Bool = false,
        latexAnalyticsLogger: (@Sendable (LatexAnalyticsEvent) -> Void)? = nil
    ) {
        self.attachmentViewCacheEnabled = attachmentViewCacheEnabled
        self.disableLatexEscapeAllPunctuation = disableLatexEscapeAllPunctuation
        self.latexAnalyticsLogger = latexAnalyticsLogger
    }

    func preprocess(markdown: inout String) {}
    func postProcess(result: inout MarkdownResult, options: MarkdownOptions, traitCollection: PlatformAppearance) {}
}

// MARK: - WritingBlockPlugin

/// Mirrors OpenAI's `OAIMarkdown.WritingBlockPlugin`.
class WritingBlockPlugin: MarkdownPlugin {
    let disableParsingUnclosedWritingBlocks: Bool

    init(disableParsingUnclosedWritingBlocks: Bool = false) {
        self.disableParsingUnclosedWritingBlocks = disableParsingUnclosedWritingBlocks
    }

    func preprocess(markdown: inout String) {}
    func postProcess(result: inout MarkdownResult, options: MarkdownOptions, traitCollection: PlatformAppearance) {}

    static func writingBlockRanges(in text: String, disableParsingUnclosedWritingBlocks: Bool = false) -> [WritingBlockRange] {
        []
    }

    struct WritingBlockRange {
        var startToken: String
        var endToken: String
        var range: Range<String.Index>
    }
}

// MARK: - CodeCitationMarkdownPlugin

/// Mirrors OpenAI's `OAIMarkdown.CodeCitationMarkdownPlugin`.
class CodeCitationMarkdownPlugin: MarkdownPlugin {
    static var codeCitationToken: String { "[[citation" }

    func preprocess(markdown: inout String) {}
    func postProcess(result: inout MarkdownResult, options: MarkdownOptions, traitCollection: PlatformAppearance) {}
}

// MARK: - CodeOnlyAutoDetectURLPlugin

/// Mirrors OpenAI's `OAIMarkdown.CodeOnlyAutoDetectURLPlugin`.
class CodeOnlyAutoDetectURLPlugin: CodeOnlyMarkdownPlugin {
    init() {}
    func postProcess(result: inout CodeOnlyMarkdownResult, traitCollection: PlatformAppearance, options: MarkdownOptions) {}
}
