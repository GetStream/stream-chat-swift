import SwiftUI

/// The characteristics of a font.
struct FontProperties: Hashable {
  /// The font family.
  enum Family: Hashable {
    /// The system font family.
    case system(Font.Design = .default)

    /// A custom font family with the given name.
    case custom(String)
  }

  /// The font family variant.
  enum FamilyVariant: Hashable {
    /// No variant. Use the current font family.
    case normal

    /// A fixed-width font from the current family, if available.
    case monospaced
  }

  /// The font caps variant.
  enum CapsVariant: Hashable {
    /// Don't use a font caps variant.
    case normal

    /// Enable all small capitals.
    case smallCaps

    /// Enable lowercase small capitals.
    case lowercaseSmallCaps

    /// Enable uppercase small capitals.
    case uppercaseSmallCaps
  }

  /// The font digit variant.
  enum DigitVariant: Hashable {
    /// Don't use a font digit variant.
    case normal

    /// Enable monospaced digits.
    case monospaced
  }

  /// The font style.
  enum Style {
    /// Don't use a font style.
    case normal

    /// Select an italic font.
    case italic
  }

  /// A platform-dependent default font size.
  static var defaultSize: CGFloat {
    #if os(macOS)
      return 13
    #elseif os(iOS)
      return 17
    #elseif os(tvOS)
      return 29
    #elseif os(watchOS)
      return 16
    #else
      return 16
    #endif
  }

  /// A platform-dependent default font weight.
  static var defaultWeight: Font.Weight {
    #if os(tvOS)
      return .medium
    #else
      return .regular
    #endif
  }

  /// The font family.
  var family: Family = .system()

  /// The font family variant.
  var familyVariant: FamilyVariant = .normal

  /// The font caps variant.
  var capsVariant: CapsVariant = .normal

  /// The font digit variant.
  var digitVariant: DigitVariant = .normal

  /// The font style.
  var style: Style = .normal

  /// The font weight.
  var weight: Font.Weight = Self.defaultWeight

  /// The font width.
  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  var width: Font.Width {
    get { self.widthStorage.map(Font.Width.init) ?? .standard }
    set { self.widthStorage = newValue.value }
  }

  private var widthStorage: CGFloat?

  /// The font size.
  var size: CGFloat = Self.defaultSize

  /// The font scale.
  var scale: CGFloat = 1

  /// The scaled font size.
  var scaledSize: CGFloat {
    round(self.size * self.scale)
  }

  /// Creates a font  properties value.
  /// - Parameters:
  ///   - family: The font family.
  ///   - familyVariant: The font family variant.
  ///   - capsVariant: The font caps variant.
  ///   - digitVariant: The font digit variant.
  ///   - style: The font style.
  ///   - weight: The font weight.
  ///   - width: The font width
  ///   - size: The font size.
  ///   - scale: The font scale.
  @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
  init(
    family: FontProperties.Family = .system(),
    familyVariant: FontProperties.FamilyVariant = .normal,
    capsVariant: FontProperties.CapsVariant = .normal,
    digitVariant: FontProperties.DigitVariant = .normal,
    style: FontProperties.Style = .normal,
    weight: Font.Weight = Self.defaultWeight,
    width: Font.Width,
    size: CGFloat = Self.defaultSize,
    scale: CGFloat = 1
  ) {
    self.init(
      family: family,
      familyVariant: familyVariant,
      capsVariant: capsVariant,
      digitVariant: digitVariant,
      style: style,
      weight: weight,
      size: size,
      scale: scale
    )
    self.width = width
  }

  /// Creates a font  properties value.
  /// - Parameters:
  ///   - family: The font family.
  ///   - familyVariant: The font family variant.
  ///   - capsVariant: The font caps variant.
  ///   - digitVariant: The font digit variant.
  ///   - style: The font style.
  ///   - weight: The font weight.
  ///   - size: The font size.
  ///   - scale: The font scale.
  init(
    family: FontProperties.Family = .system(),
    familyVariant: FontProperties.FamilyVariant = .normal,
    capsVariant: FontProperties.CapsVariant = .normal,
    digitVariant: FontProperties.DigitVariant = .normal,
    style: FontProperties.Style = .normal,
    weight: Font.Weight = Self.defaultWeight,
    size: CGFloat = Self.defaultSize,
    scale: CGFloat = 1
  ) {
    self.family = family
    self.familyVariant = familyVariant
    self.capsVariant = capsVariant
    self.digitVariant = digitVariant
    self.style = style
    self.weight = weight
    self.size = size
    self.scale = scale
  }
}

extension FontProperties: TextStyle {
  func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.fontProperties = self
  }
}
