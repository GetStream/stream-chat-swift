import Foundation

/// A Markdown thematic break element.
///
/// Use a thematic break element to define thematic changes in the content.
///
/// ```swift
/// Markdown {
///   Paragraph {
///     "This is an example of a thematic break."
///   }
///   ThematicBreak()
///   Paragraph {
///     "We have used a thematic break above this paragraph."
///   }
/// }
/// ```
///
/// ![](ThematicBreak)
@available(iOS 15.0, macOS 12.0, *)
struct ThematicBreak: MarkdownContentProtocol {
  var _markdownContent: MarkdownContent {
    .init(blocks: [.thematicBreak])
  }

  init() {}
}
