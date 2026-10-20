import Foundation

/// A text style that doesn't apply any text style.
struct EmptyTextStyle: TextStyle {
  /// Creates an empty text style.
  init() {}

  func _collectAttributes(in: inout AttributeContainer) {}
}
