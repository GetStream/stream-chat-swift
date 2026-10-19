/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

#if !os(Linux)

/// A theme describes what fonts and colors to use when rendering
/// certain output formats - such as `NSAttributedString`. Several
/// default implementations are provided - see SplashTheme+Defaults.swift.
struct SplashTheme {
    /// What font to use to render the highlighted text
    var font: SplashFont
    /// What color to use for plain text (no highlighting)
    var plainTextColor: SplashColor
    /// What color to use for the background
    var backgroundColor: SplashColor
    /// What color to use for the text's highlighted tokens
    var tokenColors: [TokenType: SplashColor]

    init(font: SplashFont,
                plainTextColor: SplashColor,
                tokenColors: [TokenType: SplashColor],
                backgroundColor: SplashColor = SplashColor(white: 0.12, alpha: 1)) {
        self.font = font
        self.plainTextColor = plainTextColor
        self.tokenColors = tokenColors
        self.backgroundColor = backgroundColor
    }
}

#endif
