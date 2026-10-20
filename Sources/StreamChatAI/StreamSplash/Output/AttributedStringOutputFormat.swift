/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

#if !os(Linux)

import Foundation

/// Output format to use to generate an NSAttributedString from the
/// highlighted code. A `SplashTheme` is used to determine what fonts and
/// colors to use for the various tokens.
struct AttributedStringOutputFormat: OutputFormat {
    var theme: SplashTheme

    init(theme: SplashTheme) {
        self.theme = theme
    }

    func makeBuilder() -> Builder {
        return Builder(theme: theme)
    }
}

extension AttributedStringOutputFormat {
    struct Builder: OutputBuilder {
        private let theme: SplashTheme
        private lazy var font = theme.font.load()
        private var string = NSMutableAttributedString()

        fileprivate init(theme: SplashTheme) {
            self.theme = theme
        }

        mutating func addToken(_ token: String, ofType type: TokenType) {
            let color = theme.tokenColors[type] ?? SplashColor(red: 1, green: 1, blue: 1)
            string.append(token, font: font, color: color)
        }

        mutating func addPlainText(_ text: String) {
            string.append(text, font: font, color: theme.plainTextColor)
        }

        mutating func addWhitespace(_ whitespace: String) {
            let color = SplashColor(red: 1, green: 1, blue: 1)
            string.append(whitespace, font: font, color: color)
        }

        func build() -> NSAttributedString {
            return NSAttributedString(attributedString: string)
        }
    }
}

private extension NSMutableAttributedString {
    func append(_ string: String, font: SplashFont.Loaded, color: SplashColor) {
        let attributedString = NSAttributedString(string: string, attributes: [
            .foregroundColor: color,
            .font: font
        ])

        append(attributedString)
    }
}

#endif
