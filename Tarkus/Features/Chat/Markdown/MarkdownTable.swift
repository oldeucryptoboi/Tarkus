import Foundation

// MARK: - MarkdownTable

/// GFM table model with head, body, and optional source position.
/// Mirrors OpenAI's `OAIMarkdown.MarkdownTable`.
struct MarkdownTable: Equatable {

    var head: Head
    var body: Body
    var sourcePosition: MarkdownSourcePosition?

    // MARK: - Head

    struct Head: Equatable {
        var cells: [Cell]
    }

    // MARK: - Body

    struct Body: Equatable {
        var rows: [Row]
    }

    // MARK: - Row

    struct Row: Equatable {
        var cells: [Cell]
    }

    // MARK: - Cell

    /// Table cell holding a full `MarkdownResult`.
    /// Mirrors OpenAI's `OAIMarkdown.MarkdownTable.Cell`.
    struct Cell: Equatable {
        var result: MarkdownResult

        init(result: MarkdownResult) {
            self.result = result
        }

        /// Backward-compat convenience: create a cell from an attributed string.
        /// Wraps the text in a single-item MarkdownResult.
        init(text: NSAttributedString) {
            self.result = MarkdownResult(items: [.text(.init(text: text))])
        }

        /// Backward-compat convenience: the first text item's attributed string.
        /// Used by MarkdownTableBlockView for rendering.
        var text: NSAttributedString {
            for item in result.items {
                if case .text(let t) = item {
                    return t.text
                }
            }
            return NSAttributedString()
        }
    }

    // MARK: - Equatable

    static func == (lhs: MarkdownTable, rhs: MarkdownTable) -> Bool {
        lhs.head == rhs.head && lhs.body == rhs.body
        // sourcePosition is Any — skip for equality
    }

    // MARK: - Hashable (Tarkus internal — needed for Item.id)

    /// Internal hash for use in MarkdownResult.Item.id computation.
    func hash(into hasher: inout Hasher) {
        for cell in head.cells {
            hasher.combine(cell.text.string)
        }
        for row in body.rows {
            for cell in row.cells {
                hasher.combine(cell.text.string)
            }
        }
    }

    var hashValue: Int {
        var hasher = Hasher()
        hash(into: &hasher)
        return hasher.finalize()
    }
}
