import SwiftUI

/// The properties of a Markdown table cell.
///
/// The theme ``Theme/tableCell`` block style receives a `TableCellConfiguration`
/// input in its `body` closure.
struct TableCellConfiguration {
  /// A type-erased view of a Markdown table cell.
  struct Label: View {
    init<L: View>(_ label: L) {
      self.body = AnyView(label)
    }

    let body: AnyView
  }

  /// The table cell row index.
  let row: Int

  /// The table cell column index.
  let column: Int

  /// The table cell view.
  let label: Label

  /// The table cell content.
  let content: MarkdownContent
}
