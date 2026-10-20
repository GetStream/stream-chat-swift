import SwiftUI

/// A text style that sets the text background color.
struct BackgroundColor: TextStyle {
  private let backgroundColor: Color?

  /// Creates a background color text style.
  /// - Parameter backgroundColor: The background color.
  init(_ backgroundColor: Color?) {
    self.backgroundColor = backgroundColor
  }

  func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.backgroundColor = self.backgroundColor
  }
}
