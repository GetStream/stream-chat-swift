import Foundation

/// A text style that sets the spacing, or kerning, between the characters of the text.
struct TextKerning: TextStyle {
  private let kern: CGFloat?

  /// Creates a text kerning text style.
  /// - Parameter kern: The spacing to use between individual characters in the text.
  init(_ kern: CGFloat?) {
    self.kern = kern
  }

  func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.kern = self.kern
  }
}
