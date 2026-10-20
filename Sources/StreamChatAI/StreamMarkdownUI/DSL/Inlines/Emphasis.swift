import Foundation

/// An emphasized text in a Markdown content block.
struct Emphasis: InlineContentProtocol {
  var _inlineContent: InlineContent {
    .init(inlines: [.emphasis(children: self.content.inlines)])
  }

  private let content: InlineContent

  init(content: InlineContent) {
    self.content = content
  }

  /// Creates an emphasized inline by applying the emphasis style to a string.
  /// - Parameter text: The text to emphasize
  init(_ text: String) {
    self.init(content: .init(inlines: [.text(text)]))
  }

  /// Creates an emphasized inline by applying the emphasis style to other inline content.
  /// - Parameter content: An inline content builder that returns the inlines to emphasize.
  init(@InlineContentBuilder content: () -> InlineContent) {
    self.init(content: content())
  }
}
