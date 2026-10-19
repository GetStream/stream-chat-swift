import Foundation

/// A result builder that creates table columns from closures.
///
/// You don't call the methods of the result builder directly. Instead, MarkdownUI annotates the `columns`
/// parameter of the various ``TextTable`` initializers with the `@TextTableColumnBuilder` attribute,
/// implicitly calling this builder for you.
@resultBuilder enum TextTableColumnBuilder<RowValue> {
  static func buildBlock(
    _ components: [TextTableColumn<RowValue>]...
  ) -> [TextTableColumn<RowValue>] {
    components.flatMap { $0 }
  }

  static func buildExpression(
    _ expression: TextTableColumn<RowValue>
  ) -> [TextTableColumn<RowValue>] {
    [expression]
  }

  static func buildArray(
    _ components: [[TextTableColumn<RowValue>]]
  ) -> [TextTableColumn<RowValue>] {
    components.flatMap { $0 }
  }

  static func buildOptional(
    _ component: [TextTableColumn<RowValue>]?
  ) -> [TextTableColumn<RowValue>] {
    component ?? []
  }

  static func buildEither(
    first component: [TextTableColumn<RowValue>]
  ) -> [TextTableColumn<RowValue>] {
    component
  }

  static func buildEither(
    second component: [TextTableColumn<RowValue>]
  ) -> [TextTableColumn<RowValue>] {
    component
  }
}
