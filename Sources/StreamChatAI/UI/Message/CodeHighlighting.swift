//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// Highlights a code block's code away from the main thread, one version at a time: a model can
// write code that takes the highlighter long, and that must not freeze the app. While a reply is
// written, the code highlighted last keeps its colors, and the code written since shows plain
// until a later version is highlighted.
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

    @Published private(set) var highlighted: HighlightedCode?
    private(set) var isHighlighting = false

    // The code asked for last, and the code to highlight once the highlighter is free.
    private var latest: String?
    private var next: String?

    private var colored: (code: HighlightedCode, colors: CodeColors, text: AttributedString)?

    func highlight(_ code: String) {
        latest = code
        next = nil
        guard code.utf16.count <= Self.maxLength, highlighted?.code != code else { return }
        if let cached = Self.cache.object(forKey: code as NSString) {
            highlighted = cached
        } else if isHighlighting {
            next = code
        } else {
            start(code)
        }
    }

    func text(for code: String, colors: CodeColors) -> AttributedString {
        guard let highlighted, code.hasPrefix(highlighted.code) else {
            return colors.plain(code)
        }
        let text = coloredText(of: highlighted, colors: colors)
        let rest = code.dropFirst(highlighted.code.count)
        return rest.isEmpty ? text : text + colors.plain(rest)
    }

    private func start(_ code: String) {
        isHighlighting = true
        Task {
            let runs = await Task.detached(priority: .userInitiated) {
                SyntaxHighlighter(format: CodeRunsFormat()).highlight(code)
            }.value
            let result = HighlightedCode(code: code, runs: runs)
            Self.cache.setObject(result, forKey: code as NSString, cost: code.utf16.count)
            if showsMoreOfLatest(code) {
                highlighted = result
            }
            isHighlighting = false
            if let next {
                self.next = nil
                start(next)
            }
        }
    }

    // Whether highlighting `code` shows more of the code asked for last than what is shown. Code
    // asked for since, such as a version found in the cache, can show more than older code does.
    private func showsMoreOfLatest(_ code: String) -> Bool {
        guard let latest, latest.hasPrefix(code) else { return false }
        guard let shown = highlighted?.code, latest.hasPrefix(shown) else { return true }
        return code.utf8.count > shown.utf8.count
    }

    // Coloring takes time in proportion to the code's length too, so its text is kept while the
    // highlighted code and the colors stay the same, such as while the rest of a reply is written.
    private func coloredText(of code: HighlightedCode, colors: CodeColors) -> AttributedString {
        if let colored, colored.code === code, colored.colors == colors {
            return colored.text
        }
        let text = colors.text(for: code.runs)
        colored = (code, colors, text)
        return text
    }
}

@available(iOS 15.0, macOS 12.0, *)
final class HighlightedCode {
    let code: String
    let runs: [CodeRun]

    init(code: String, runs: [CodeRun]) {
        self.code = code
        self.runs = runs
    }
}
