import SwiftUI

/// The properties of a Markdown block.
///
/// Most theme ``BlockStyle`` instances receive a `BlockConfiguration` input in their
/// `body` closure. The configuration ``BlockConfiguration/label-swift.property``
/// property reflects the block's content.
struct BlockConfiguration {
  /// A type-erased view of a Markdown block.
  struct Label: View {
    init<L: View>(_ label: L) {
      self.body = AnyView(label)
    }

    let body: AnyView
  }

  /// The Markdown block view.
  let label: Label

  /// The content of the Markdown block.
  ///
  /// This property provides access to different representations of the block content.
  /// For example, you can use ``MarkdownContent/renderMarkdown()``
  /// to get the Markdown formatted text or ``MarkdownContent/renderPlainText()``
  /// to get the plain text of the block content.
  let content: MarkdownContent
}
