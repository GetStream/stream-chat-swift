import Foundation

/// A text style that sets whether the font should be styled with a normal or italic face from its font family.
struct FontStyle: TextStyle {
  private let style: FontProperties.Style

  /// Creates a font style text style.
  /// - Parameter style: The font style.
  init(_ style: FontProperties.Style) {
    self.style = style
  }

  func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.fontProperties?.style = self.style
  }
}
