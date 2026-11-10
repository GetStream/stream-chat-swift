import Foundation

/// A text style that doesn't apply any text style.
@available(iOS 15.0, macOS 12.0, *)
struct EmptyTextStyle: TextStyle {
  /// Creates an empty text style.
  init() {}

  func _collectAttributes(in: inout AttributeContainer) {}
}
