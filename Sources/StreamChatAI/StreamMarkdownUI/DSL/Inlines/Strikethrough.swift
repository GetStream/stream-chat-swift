import Foundation

/// A deleted or redacted text in a Markdown content block.
struct Strikethrough: InlineContentProtocol {
  var _inlineContent: InlineContent {
    .init(inlines: [.strikethrough(children: self.content.inlines)])
  }

  private let content: InlineContent

  init(content: InlineContent) {
    self.content = content
  }

  /// Creates a deleted inline by applying the deleted style to a string.
  /// - Parameter text: The text to delete.
  init(_ text: String) {
    self.init(content: .init(inlines: [.text(text)]))
  }

  /// Creates a deleted inline by applying the deleted style to other inline content.
  /// - Parameter content: An inline content builder that returns the inlines to delete.
  init(@InlineContentBuilder content: () -> InlineContent) {
    self.init(content: content())
  }
}
