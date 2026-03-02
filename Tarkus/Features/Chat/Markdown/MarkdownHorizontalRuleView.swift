import SwiftUI

// MARK: - MarkdownHorizontalRuleView

/// Renders a horizontal rule / thematic break.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownHorizontalRuleView`.
struct MarkdownHorizontalRuleView: View {

    let options: MarkdownOptions

    var body: some View {
        Rectangle()
            .fill(options.horizontalRuleColor)
            .frame(height: options.horizontalRuleHeight)
            .padding(.vertical, 4)
    }
}
