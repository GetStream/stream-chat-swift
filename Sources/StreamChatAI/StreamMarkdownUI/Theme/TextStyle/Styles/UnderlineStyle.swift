import SwiftUI

/// A text style that sets the underline line style of the text.
struct UnderlineStyle: TextStyle {
  private let lineStyle: Text.LineStyle?

  /// Creates an underline style text style.
  /// - Parameter lineStyle: The line style.
  init(_ lineStyle: Text.LineStyle?) {
    self.lineStyle = lineStyle
  }

  func _collectAttributes(in attributes: inout AttributeContainer) {
    attributes.underlineStyle = self.lineStyle
  }
}
