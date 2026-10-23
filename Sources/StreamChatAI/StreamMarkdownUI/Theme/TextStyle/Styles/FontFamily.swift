import Foundation

/// A text style that sets the text font family.
struct FontFamily: TextStyle {
  private let family: FontProperties.Family

  /// Creates a font family text style.
  /// - Parameter family: The font family.
  init(_ family: FontProperties.Family) {
    self.family = family
  }

  func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.fontProperties?.family = self.family
  }
}
