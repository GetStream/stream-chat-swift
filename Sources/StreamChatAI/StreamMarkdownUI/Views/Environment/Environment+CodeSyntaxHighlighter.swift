import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
extension View {
  /// Sets the code syntax highlighter for the Markdown code blocks in a view hierarchy.
  /// - Parameter codeSyntaxHighlighter: The code syntax highlighter to set. Use
  ///                                    ``CodeSyntaxHighlighter/plainText`` or a custom syntax
  ///                                    highlighter that you define by creating a type that conforms to the
  ///                                    ``CodeSyntaxHighlighter`` protocol.
  /// - Returns: A view that uses the specified code syntax highlighter for itself and its
  ///            child views.
  func markdownCodeSyntaxHighlighter(
    _ codeSyntaxHighlighter: CodeSyntaxHighlighter
  ) -> some View {
    self.environment(\.codeSyntaxHighlighter, codeSyntaxHighlighter)
  }
}

@available(iOS 15.0, macOS 12.0, *)
extension EnvironmentValues {
  var codeSyntaxHighlighter: CodeSyntaxHighlighter {
    get { self[CodeSyntaxHighlighterKey.self] }
    set { self[CodeSyntaxHighlighterKey.self] = newValue }
  }
}

@available(iOS 15.0, macOS 12.0, *)
private struct CodeSyntaxHighlighterKey: EnvironmentKey {
  static var defaultValue: CodeSyntaxHighlighter { .plainText }
}
