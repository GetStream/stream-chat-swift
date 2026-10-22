import Foundation

/// A code span in a Markdown content block.
struct Code: InlineContentProtocol {
  var _inlineContent: InlineContent {
    .init(inlines: [.code(self.text)])
  }

  private let text: String

  /// Creates a code span inline element.
  /// - Parameter text: The text content inside the code span.
  init(_ text: String) {
    self.text = text
  }
}
