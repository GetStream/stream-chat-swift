//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// Highlights a code block's code away from the main thread, one version at a time: a model can
// write code that takes the highlighter long, and that must not freeze the app. While a reply is
// written, the code highlighted last keeps its colors, and the code written since shows plain
// until the next version is highlighted.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class CodeHighlighting: ObservableObject {
    // Longer code shows plain, since highlighting takes time in proportion to the code's length.
    static let maxLength = 10000

    @Published private(set) var highlighted: (code: String, text: AttributedString)?

    private var isHighlighting = false
    private var next: (code: String, format: TextOutputFormat)?

    // A code block shown again, such as when its reply scrolls back into view, is shown highlighted
    // from the start.
    private static let cache: NSCache<NSString, HighlightedText> = {
        let cache = NSCache<NSString, HighlightedText>()
        cache.totalCostLimit = 1_000_000
        return cache
    }()

    func highlight(_ code: String, format: TextOutputFormat) {
        guard code.utf16.count <= Self.maxLength, highlighted?.code != code else { return }
        if let cached = Self.cache.object(forKey: code as NSString) {
            highlighted = (code, cached.text)
            return
        }
        next = (code, format)
        if !isHighlighting {
            highlightNext()
        }
    }

    func text(for code: String, plainTextColor: Color) -> AttributedString {
        guard let highlighted else {
            return Self.plain(code[...], color: plainTextColor)
        }
        if highlighted.code == code {
            return highlighted.text
        }
        if code.hasPrefix(highlighted.code) {
            return highlighted.text + Self.plain(code.dropFirst(highlighted.code.count), color: plainTextColor)
        }
        return Self.plain(code[...], color: plainTextColor)
    }

    private func highlightNext() {
        guard let (code, format) = next else { return }
        next = nil
        isHighlighting = true
        Task {
            let text = await Task.detached(priority: .userInitiated) {
                SyntaxHighlighter(format: format).highlight(code)
            }.value
            Self.cache.setObject(HighlightedText(text), forKey: code as NSString, cost: code.utf16.count)
            highlighted = (code, text)
            isHighlighting = false
            highlightNext()
        }
    }

    private static func plain(_ code: Substring, color: Color) -> AttributedString {
        var text = AttributedString(code)
        text.foregroundColor = color
        return text
    }
}

@available(iOS 15.0, macOS 12.0, *)
private final class HighlightedText {
    let text: AttributedString

    init(_ text: AttributedString) {
        self.text = text
    }
}
