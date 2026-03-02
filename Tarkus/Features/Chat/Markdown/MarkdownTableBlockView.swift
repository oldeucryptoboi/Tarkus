import SwiftUI

#if canImport(AppKit)
import AppKit
#else
import UIKit
#endif

// MARK: - MarkdownTableBlockView

/// Renders a GFM table with header, striped rows, and leading alignment.
/// Mirrors OpenAI's table rendering approach.
///
/// Note: Column alignments were removed from MarkdownTable to match OAI.
/// All columns now use leading alignment. If alignment support is needed
/// later, it can be derived from sourcePosition metadata or a post-process step.
struct MarkdownTableBlockView: View {

    let table: MarkdownTable
    let options: MarkdownOptions

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header row
                headerRow

                Divider()
                    .background(Color(options.tableBorderColor))

                // Body rows
                ForEach(table.body.rows.indices, id: \.self) { rowIndex in
                    bodyRow(table.body.rows[rowIndex], index: rowIndex)

                    if rowIndex < table.body.rows.count - 1 {
                        Divider()
                            .background(Color(options.tableBorderColor).opacity(0.5))
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: options.tableBorderCornerRadius)
                    .stroke(Color(options.tableBorderColor), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: options.tableBorderCornerRadius))
        }
    }

    // MARK: - Rows

    private var headerRow: some View {
        HStack(spacing: 0) {
            ForEach(table.head.cells.indices, id: \.self) { col in
                Text(AttributedString(table.head.cells[col].text))
                    .font(.system(size: options.tableTextStyle.platformAgnosticFont().pointSize, weight: .semibold))
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: 60, alignment: .leading)
                    .padding(EdgeInsets(
                        top: options.tableCellInsets.top,
                        leading: options.tableCellInsets.leading,
                        bottom: options.tableCellInsets.bottom,
                        trailing: options.tableCellInsets.trailing
                    ))
            }
        }
        .background(Color(options.tableHeaderBackgroundColor))
    }

    private func bodyRow(_ row: MarkdownTable.Row, index: Int) -> some View {
        let cells = paddedCells(row)
        return HStack(spacing: 0) {
            ForEach(cells.indices, id: \.self) { col in
                Text(AttributedString(cells[col].text))
                    .font(.system(size: options.tableTextStyle.platformAgnosticFont().pointSize))
                    .fixedSize(horizontal: true, vertical: false)
                    .frame(minWidth: 60, alignment: .leading)
                    .padding(EdgeInsets(
                        top: options.tableCellInsets.top,
                        leading: options.tableCellInsets.leading,
                        bottom: options.tableCellInsets.bottom,
                        trailing: options.tableCellInsets.trailing
                    ))
            }
        }
        .background(
            index % 2 == 1
                ? Color(options.tableStripeBackgroundColor)
                : Color.clear
        )
    }

    // MARK: - Helpers

    private func paddedCells(_ row: MarkdownTable.Row) -> [MarkdownTable.Cell] {
        if row.cells.count < table.head.cells.count {
            return row.cells + Array(
                repeating: MarkdownTable.Cell(text: NSAttributedString(string: "")),
                count: table.head.cells.count - row.cells.count
            )
        }
        return row.cells
    }
}
