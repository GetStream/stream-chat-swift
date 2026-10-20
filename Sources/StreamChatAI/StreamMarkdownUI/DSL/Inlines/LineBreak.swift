import Foundation

/// A line break in a Markdown content block.
///
/// You can use a line break inline to force line breaks in a text.
struct LineBreak: InlineContentProtocol {
  /// Creates a line break inline.
  init() {}

  var _inlineContent: InlineContent {
    .init(inlines: [.lineBreak])
  }
}
