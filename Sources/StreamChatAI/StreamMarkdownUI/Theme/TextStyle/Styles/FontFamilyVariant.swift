import Foundation

/// A text style that adjusts the font to use an alternate variant.
@available(iOS 15.0, macOS 12.0, *)
struct FontFamilyVariant: TextStyle {
  private let familyVariant: FontProperties.FamilyVariant

  /// Creates a font family variant text style.
  /// - Parameter familyVariant: The font family variant.
  init(_ familyVariant: FontProperties.FamilyVariant) {
    self.familyVariant = familyVariant
  }

  func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.fontProperties?.familyVariant = self.familyVariant
  }
}
