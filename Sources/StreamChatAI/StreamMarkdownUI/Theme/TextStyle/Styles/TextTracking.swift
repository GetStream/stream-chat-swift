import Foundation

/// A text style that sets the tracking of the text.
struct TextTracking: TextStyle {
  private let tracking: CGFloat?

  /// Creates a text tracking text style.
  /// - Parameter tracking: The amount of additional space, in points, that is added to each character cluster.
  init(_ tracking: CGFloat?) {
    self.tracking = tracking
  }

  func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.tracking = self.tracking
  }
}
