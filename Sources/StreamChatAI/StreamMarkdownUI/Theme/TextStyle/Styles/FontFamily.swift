import Foundation

/// A text style that sets the text font family.
@available(iOS 15.0, macOS 12.0, *)
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
