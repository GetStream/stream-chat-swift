import Foundation

/// A soft break in a Markdown content block.
///
/// A ``Markdown`` view will display a soft break as a space.
struct SoftBreak: InlineContentProtocol {
  /// Creates a soft break inline element.
  init() {}

  var _inlineContent: InlineContent {
    .init(inlines: [.softBreak])
  }
}

extension SoftBreak {
  enum Mode {
    /// Treat a soft break as a space
    case space

    /// Treat a soft break as a line break
    case lineBreak
  }
}
