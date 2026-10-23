import SwiftUI

/// The properties of a Markdown code block.
///
/// The theme ``Theme/codeBlock`` block style receives a `CodeBlockConfiguration`
/// input in its `body` closure.
struct CodeBlockConfiguration {
  /// A type-erased view of a Markdown code block.
  struct Label: View {
    init<L: View>(_ label: L) {
      self.body = AnyView(label)
    }

    let body: AnyView
  }

  /// The code block language, if present.
  let language: String?

  /// The code block contents.
  let content: String

  /// The code block view.
  let label: Label
}
