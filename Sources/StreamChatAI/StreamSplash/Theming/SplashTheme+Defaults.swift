/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

import Foundation

#if !os(Linux)

extension SplashTheme {
    /// Create a theme matching the "Sundell's Colors" Xcode theme
    static func sundellsColors(withFont font: SplashFont) -> SplashTheme {
        return SplashTheme(
            font: font,
            plainTextColor: SplashColor(
                red: 0.66,
                green: 0.74,
                blue: 0.74
            ),
            tokenColors: [
                .keyword: SplashColor(red: 0.91, green: 0.2, blue: 0.54),
                .string: SplashColor(red: 0.98, green: 0.39, blue: 0.12),
                .type: SplashColor(red: 0.51, green: 0.51, blue: 0.79),
                .call: SplashColor(red: 0.2, green: 0.56, blue: 0.9),
                .number: SplashColor(red: 0.86, green: 0.44, blue: 0.34),
                .comment: SplashColor(red: 0.42, green: 0.54, blue: 0.58),
                .property: SplashColor(red: 0.13, green: 0.67, blue: 0.62),
                .dotAccess: SplashColor(red: 0.57, green: 0.7, blue: 0),
                .preprocessing: SplashColor(red: 0.71, green: 0.54, blue: 0)
            ],
            backgroundColor: SplashColor(
                red: 0.098,
                green: 0.098,
                blue: 0.098
            )
        )
    }

    /// Create a theme matching Xcode's "Midnight" theme
    static func midnight(withFont font: SplashFont) -> SplashTheme {
        return SplashTheme(
            font: font,
            plainTextColor: SplashColor(
                red: 1,
                green: 1,
                blue: 1
            ),
            tokenColors: [
                .keyword: SplashColor(red: 0.828, green: 0.095, blue: 0.583),
                .string: SplashColor(red: 1.0, green: 0.171, blue: 0.219),
                .type: SplashColor(red: 0.137, green: 1.0, blue: 0.512),
                .call: SplashColor(red: 0.137, green: 1.0, blue: 0.512),
                .number: SplashColor(red: 0.469, green: 0.426, blue: 1.00),
                .comment: SplashColor(red: 0.255, green: 0.801, blue: 0.27),
                .property: SplashColor(red: 0.431, green: 0.714, blue: 0.533),
                .dotAccess: SplashColor(red: 0.431, green: 0.714, blue: 0.533),
                .preprocessing: SplashColor(red: 0.896, green: 0.488, blue: 0.284)
            ],
            backgroundColor: SplashColor(
                red: 0,
                green: 0,
                blue: 0
            )
        )
    }

    /// Creating a theme matching the colors used for the WWDC 2017 sample code
    static func wwdc17(withFont font: SplashFont) -> SplashTheme {
        return SplashTheme(
            font: font,
            plainTextColor: SplashColor(
                red: 0.84,
                green: 0.84,
                blue: 0.84
            ),
            tokenColors: [
                .keyword: SplashColor(red: 0.992, green: 0.791, blue: 0.45),
                .string: SplashColor(red: 0.966, green: 0.517, blue: 0.29),
                .type: SplashColor(red: 0.431, green: 0.714, blue: 0.533),
                .call: SplashColor(red: 0.431, green: 0.714, blue: 0.533),
                .number: SplashColor(red: 0.559, green: 0.504, blue: 0.745),
                .comment: SplashColor(red: 0.484, green: 0.483, blue: 0.504),
                .property: SplashColor(red: 0.431, green: 0.714, blue: 0.533),
                .dotAccess: SplashColor(red: 0.431, green: 0.714, blue: 0.533),
                .preprocessing: SplashColor(red: 0.992, green: 0.791, blue: 0.45)
            ],
            backgroundColor: SplashColor(
                red: 0.18,
                green: 0.19,
                blue: 0.2
            )
        )
    }

    /// Creating a theme matching the colors used for the WWDC 2018 sample code
    static func wwdc18(withFont font: SplashFont) -> SplashTheme {
        return SplashTheme(
            font: font,
            plainTextColor: SplashColor(
                red: 1,
                green: 1,
                blue: 1
            ),
            tokenColors: [
                .keyword: SplashColor(red: 0.948, green: 0.140, blue: 0.547),
                .string: SplashColor(red: 0.988, green: 0.273, blue: 0.317),
                .type: SplashColor(red: 0.584, green: 0.898, blue: 0.361),
                .call: SplashColor(red: 0.584, green: 0.898, blue: 0.361),
                .number: SplashColor(red: 0.587, green: 0.517, blue: 0.974),
                .comment: SplashColor(red: 0.424, green: 0.475, blue: 0.529),
                .property: SplashColor(red: 0.584, green: 0.898, blue: 0.361),
                .dotAccess: SplashColor(red: 0.584, green: 0.898, blue: 0.361),
                .preprocessing: SplashColor(red: 0.952, green: 0.526, blue: 0.229)
            ],
            backgroundColor: SplashColor(
                red: 0.163,
                green: 0.163,
                blue: 0.182
            )
        )
    }

    /// Create a theme matching Xcode's "Sunset" theme
    static func sunset(withFont font: SplashFont) -> SplashTheme {
        return SplashTheme(
            font: font,
            plainTextColor: SplashColor(
                red: 0,
                green: 0,
                blue: 0
            ),
            tokenColors: [
                .keyword: SplashColor(red: 0.161, green: 0.259, blue: 0.467),
                .string: SplashColor(red: 0.875, green: 0.027, blue: 0.0),
                .type: SplashColor(red: 0.706, green: 0.27, blue: 0.0),
                .call: SplashColor(red: 0.278, green: 0.415, blue: 0.593),
                .number: SplashColor(red: 0.161, green: 0.259, blue: 0.467),
                .comment: SplashColor(red: 0.765, green: 0.455, blue: 0.11),
                .property: SplashColor(red: 0.278, green: 0.415, blue: 0.593),
                .dotAccess: SplashColor(red: 0.278, green: 0.415, blue: 0.593),
                .preprocessing: SplashColor(red: 0.392, green: 0.391, blue: 0.52)
            ],
            backgroundColor: SplashColor(
                red: 1,
                green: 0.99,
                blue: 0.9
            )
        )
    }

    /// Create a theme matching Xcode's "Presentation" theme
    static func presentation(withFont font: SplashFont) -> SplashTheme {
        return SplashTheme(
            font: font,
            plainTextColor: SplashColor(
                red: 0,
                green: 0,
                blue: 0
            ),
            tokenColors: [
                .keyword: SplashColor(red: 0.706, green: 0.0, blue: 0.384),
                .string: SplashColor(red: 0.729, green: 0.0, blue: 0.067),
                .type: SplashColor(red: 0.267, green: 0.537, blue: 0.576),
                .call: SplashColor(red: 0.267, green: 0.537, blue: 0.576),
                .number: SplashColor(red: 0.0, green: 0.043, blue: 1.0),
                .comment: SplashColor(red: 0.336, green: 0.376, blue: 0.42),
                .property: SplashColor(red: 0.267, green: 0.537, blue: 0.576),
                .dotAccess: SplashColor(red: 0.267, green: 0.537, blue: 0.576),
                .preprocessing: SplashColor(red: 0.431, green: 0.125, blue: 0.051)
            ],
            backgroundColor: SplashColor(
                red: 1,
                green: 1,
                blue: 1
            )
        )
    }
}

#endif
