#if canImport(AppKit)
import AppKit

extension NSView {

    /// Create a placeholder text attachment for this view.
    /// Mirrors OpenAI's NSView extension in OAIMarkdown.
    func associatedPlaceholderAttachment(plainText: String? = nil, html: String? = nil) -> MarkdownResult.TextAttachment {
        let attachment = NSTextAttachment()
        return MarkdownResult.TextAttachment(attachment: attachment, verticalOffset: nil)
    }
}

#endif
