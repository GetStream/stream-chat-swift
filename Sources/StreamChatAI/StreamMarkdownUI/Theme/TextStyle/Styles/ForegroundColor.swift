import SwiftUI

/// A text style that sets the foreground color of the text.
@available(iOS 15.0, macOS 12.0, *)
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
