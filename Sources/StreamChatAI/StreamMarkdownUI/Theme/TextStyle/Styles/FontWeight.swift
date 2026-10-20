import SwiftUI

/// A text style that adjusts the font weight.
struct FontWeight: TextStyle {
  private let weight: Font.Weight

  /// Creates a font weight text style.
  /// - Parameter weight: The font weight.
  init(_ weight: Font.Weight) {
    self.weight = weight
  }

  func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.fontProperties?.weight = self.weight
  }
}
