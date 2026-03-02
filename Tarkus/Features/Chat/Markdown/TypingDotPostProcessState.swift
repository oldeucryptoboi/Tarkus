import Foundation

// MARK: - TypingDotPostProcessState

/// Manages the state for appending a typing indicator dot to streaming markdown content.
/// Mirrors OpenAI's `OAIMarkdown.TypingDotPostProcessState`.
///
/// When streaming is active, this produces a `MarkdownPostProcess` that appends
/// a typing dot character to the last text item in the result.
final class TypingDotPostProcessState {

    /// The typing dot character used as the indicator.
    private static let typingDot = "\u{2022}" // bullet character

    /// Unique ID for the post-process step.
    private let id = "typing-dot"

    init() {}

    /// Creates a `MarkdownPostProcess` that conditionally appends a typing dot
    /// to the last text item when streaming.
    ///
    /// - Parameter showsTypingDotWhenStreaming: Whether to show the dot.
    /// - Returns: A post-process step that can be applied to a `MarkdownResult`.
    func postProcess(showsTypingDotWhenStreaming: Bool) -> MarkdownPostProcess {
        MarkdownPostProcess(id: id) { result in
            guard showsTypingDotWhenStreaming else { return }
            guard !result.items.isEmpty else { return }

            // Find the last text item and append the typing dot
            let lastIndex = result.items.count - 1
            if case .text(var textItem) = result.items[lastIndex] {
                let mutable = NSMutableAttributedString(attributedString: textItem.text)
                let dotAttrs: [NSAttributedString.Key: Any] = {
                    if mutable.length > 0 {
                        return mutable.attributes(at: mutable.length - 1, effectiveRange: nil)
                    }
                    return [:]
                }()
                mutable.append(NSAttributedString(string: " " + Self.typingDot, attributes: dotAttrs))
                textItem.text = mutable
                result.items[lastIndex] = .text(textItem)
            }
        }
    }
}
