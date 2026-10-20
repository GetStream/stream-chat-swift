import Foundation

/// A Markdown code block element.
///
/// Pre-formatted code blocks are used for writing about programming or markup source code.
/// Rather than forming normal paragraphs, the lines of a code block are interpreted literally.
///
/// ```swift
/// Markdown {
///   Paragraph {
///     "Use a group to collect multiple views into a single instance, "
///     "without affecting the layout of those views."
///   }
///   CodeBlock(language: "swift") {
///     """
///     Group {
///         Text("SwiftUI")
///         Text("Combine")
///         Text("Swift System")
///     }
///     .font(.headline)
///     """
///   }
/// }
/// ```
///
/// ![](CodeBlock)
struct CodeBlock: MarkdownContentProtocol {
  var _markdownContent: MarkdownContent {
    .init(blocks: [.codeBlock(fenceInfo: self.language, content: self.content)])
  }

  private let language: String?
  private let content: String

  init(language: String? = nil, content: String) {
    self.language = language
    self.content = content
  }

  init(language: String? = nil, content: () -> String) {
    self.init(language: language, content: content())
  }
}
