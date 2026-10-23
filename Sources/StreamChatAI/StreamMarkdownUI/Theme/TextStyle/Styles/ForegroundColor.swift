import SwiftUI

/// A text style that sets the foreground color of the text.
struct ForegroundColor: TextStyle {
  private let foregroundColor: Color?

  /// Creates a foreground color text style.
  /// - Parameter foregroundColor: The foreground color.
  init(_ foregroundColor: Color?) {
    self.foregroundColor = foregroundColor
  }

  func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.foregroundColor = self.foregroundColor
  }
}
