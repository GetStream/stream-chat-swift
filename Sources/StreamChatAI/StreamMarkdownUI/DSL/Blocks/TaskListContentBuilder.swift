import Foundation

/// A result builder that you can use to compose task lists.
///
/// You don't call the methods of the result builder directly. Instead, Swift uses them to combine the elements
/// you declare in any closure with the `@TaskListContentBuilder` attribute. In particular, you rely on
/// this behavior when you declare the `content` inside a list element initializer such as
/// ``TaskList/init(tight:items:)``.
@resultBuilder enum TaskListContentBuilder {
  static func buildBlock(_ components: [TaskListItem]...) -> [TaskListItem] {
    components.flatMap { $0 }
  }

  static func buildExpression(_ expression: String) -> [TaskListItem] {
    [.init(expression)]
  }

  static func buildExpression(_ expression: TaskListItem) -> [TaskListItem] {
    [expression]
  }

  static func buildArray(_ components: [[TaskListItem]]) -> [TaskListItem] {
    components.flatMap { $0 }
  }

  static func buildOptional(_ component: [TaskListItem]?) -> [TaskListItem] {
    component ?? []
  }

  static func buildEither(first component: [TaskListItem]) -> [TaskListItem] {
    component
  }

  static func buildEither(second component: [TaskListItem]) -> [TaskListItem] {
    component
  }
}
