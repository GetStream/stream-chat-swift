//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Splash's output as runs of code and their token types. They don't depend on colors, so they can be
// made away from the main thread and cached, and `CodeColors` colors them with the current appearance.
@available(iOS 15.0, macOS 12.0, *)
struct CodeRunsFormat: OutputFormat {
    func makeBuilder() -> Builder {
        Builder()
    }
}

// A run of code that shows in one color: a token's type, or nil for plain text and whitespace.
@available(iOS 15.0, macOS 12.0, *)
struct CodeRun: Equatable {
    var text: String
    let type: TokenType?
}

@available(iOS 15.0, macOS 12.0, *)
extension CodeRunsFormat {
    struct Builder: OutputBuilder {
        private var runs: [CodeRun] = []

        mutating func addToken(_ token: String, ofType type: TokenType) {
            add(token, type: type)
        }

        mutating func addPlainText(_ text: String) {
            add(text, type: nil)
        }

        mutating func addWhitespace(_ whitespace: String) {
            add(whitespace, type: nil)
        }

        func build() -> [CodeRun] {
            runs
        }

        // Neighboring runs of the same type are joined, so that there are fewer to color.
        private mutating func add(_ text: String, type: TokenType?) {
            if let last = runs.indices.last, runs[last].type == type {
                runs[last].text += text
            } else {
                runs.append(CodeRun(text: text, type: type))
            }
        }
    }
}
