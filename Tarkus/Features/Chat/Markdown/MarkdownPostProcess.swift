import Foundation

// MARK: - MarkdownPostProcess

/// A named post-processing step that can mutate a `MarkdownResult` after compilation.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownPostProcess`.
struct MarkdownPostProcess: Identifiable {

    /// Unique identifier for this post-process step.
    var id: AnyHashable

    /// Closure that mutates the compiled markdown result.
    var perform: (inout MarkdownResult) -> Void

    init(id: AnyHashable, perform: @escaping (inout MarkdownResult) -> Void) {
        self.id = id
        self.perform = perform
    }
}
