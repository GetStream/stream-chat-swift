//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// Highlights the code blocks of a reply away from the main thread, one at a time: a model can
// write code that takes the highlighter long, and that must not freeze the app. While a reply is
// written, the code highlighted last keeps its colors, and the code written since shows plain
// until a later version is highlighted.
//
// The reply keeps it, not its code blocks: MarkdownUI tells blocks apart by their content, so a
// code block's view is made anew each time its code changes, such as with each letter written.
//
// What's highlighted and cached are the code's runs and their token types, which don't depend on
// colors: `text(for:colors:)` colors them with the colors of the moment.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class CodeHighlighting: ObservableObject {
    // Longer code shows plain, since highlighting takes time in proportion to the code's length.
    static let maxLength = 10000

    // A code block shown again, such as when its reply scrolls back into view, is shown highlighted
    // from the start.
    private static let cache: NSCache<NSString, HighlightedCode> = {
        let cache = NSCache<NSString, HighlightedCode>()
        cache.totalCostLimit = 1_000_000
        return cache
    }()

    // The latest highlighted version of each of the reply's code blocks. Highlighted code shows in
    // any code that starts with it, so a version replaces the ones it continues.
    @Published private(set) var highlighted: [HighlightedCode] = []

    private var isHighlighting = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    // Returns once the code is highlighted, or once it won't be: it's too long, or its view went
    // away while it waited, such as the view of a version of code that has been written further.
    func highlight(_ code: String) async {
        guard code.utf16.count <= Self.maxLength, !showDone(code) else { return }
        await waitForTurn()
        defer { passTurn() }
        guard !Task.isCancelled, !showDone(code) else { return }
        let runs = await Task.detached(priority: .userInitiated) {
            SyntaxHighlighter(format: CodeRunsFormat()).highlight(code)
        }.value
        let result = HighlightedCode(code: code, runs: runs)
        Self.cache.setObject(result, forKey: code as NSString, cost: code.utf16.count)
        show(result)
    }

    func text(for code: String, colors: CodeColors) -> AttributedString {
        guard let shown = highlighting(of: code) else {
            return colors.plain(code)
        }
        let text = shown.text(colors: colors)
        let rest = code.dropFirst(shown.code.count)
        return rest.isEmpty ? text : text + colors.plain(rest)
    }

    // The code's own highlighting, or else the longest highlighted code it starts with. Code that
    // another code block continues is replaced in `highlighted`, but still found in the cache.
    private func highlighting(of code: String) -> HighlightedCode? {
        if let cached = Self.cache.object(forKey: code as NSString) {
            return cached
        }
        return highlighted
            .filter { code.hasPrefix($0.code) }
            .max { $0.code.utf8.count < $1.code.utf8.count }
    }

    // Whether the code is highlighted already, such as by another code block with the same code.
    private func showDone(_ code: String) -> Bool {
        if highlighted.contains(where: { $0.code == code }) {
            return true
        }
        guard let cached = Self.cache.object(forKey: code as NSString) else {
            return false
        }
        show(cached)
        return true
    }

    private func show(_ code: HighlightedCode) {
        highlighted.removeAll { code.code.hasPrefix($0.code) }
        highlighted.append(code)
    }

    private func waitForTurn() async {
        guard isHighlighting else {
            isHighlighting = true
            return
        }
        await withCheckedContinuation { waiting.append($0) }
    }

    private func passTurn() {
        if waiting.isEmpty {
            isHighlighting = false
        } else {
            waiting.removeFirst().resume()
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
@MainActor
final class HighlightedCode {
    let code: String
    let runs: [CodeRun]

    private var colored: (colors: CodeColors, text: AttributedString)?

    init(code: String, runs: [CodeRun]) {
        self.code = code
        self.runs = runs
    }

    // Coloring takes time in proportion to the code's length too, so the text is kept while the
    // colors stay the same, such as while the rest of a reply is written.
    func text(colors: CodeColors) -> AttributedString {
        if let colored, colored.colors == colors {
            return colored.text
        }
        let text = colors.text(for: runs)
        colored = (colors, text)
        return text
    }
}
