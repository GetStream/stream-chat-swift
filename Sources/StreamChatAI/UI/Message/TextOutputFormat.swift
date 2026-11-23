//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// Splash's output as one attributed string, so that it can be made away from the main thread, and
// shows as one text rather than a text per token.
@available(iOS 15.0, macOS 12.0, *)
struct TextOutputFormat: OutputFormat {
    let plainTextColor: Color
    let tokenColors: [TokenType: Color]

    func makeBuilder() -> Builder {
        Builder(plainTextColor: plainTextColor, tokenColors: tokenColors)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension TextOutputFormat {
    struct Builder: OutputBuilder {
        private let plainTextColor: Color
        private let tokenColors: [TokenType: Color]
        private var text = AttributedString()

        fileprivate init(plainTextColor: Color, tokenColors: [TokenType: Color]) {
            self.plainTextColor = plainTextColor
            self.tokenColors = tokenColors
        }

        mutating func addToken(_ token: String, ofType type: TokenType) {
            append(token, color: tokenColors[type] ?? plainTextColor)
        }

        mutating func addPlainText(_ text: String) {
            append(text, color: plainTextColor)
        }

        mutating func addWhitespace(_ whitespace: String) {
            text.append(AttributedString(whitespace))
        }

        func build() -> AttributedString {
            text
        }

        private mutating func append(_ string: String, color: Color) {
            var run = AttributedString(string)
            run.foregroundColor = color
            text.append(run)
        }
    }
}
