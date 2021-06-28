//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

public extension Appearance {
    struct ColorPalette {
        // MARK: - Text

        /// General textColor, should be something that contrasts great with your `background` Color
        public var text: UIColor = .streamBlack

        /// Static color which should stay the same in dark and light mode, because it's only used as text on small UI Elements
        /// such as `ChatUnreadCountView`, `GiphyBadge` or Commands icon.
        public var staticColorText: UIColor = .streamWhiteStatic
        public var subtitleText: UIColor = .streamGray

        // MARK: - Text interactions

        public var highlightedColorForColor: (UIColor) -> UIColor = { $0.withAlphaComponent(0.5) }
        public var disabledColorForColor: (UIColor) -> UIColor = { _ in .lightGray }
        public var unselectedColorForColor: (UIColor) -> UIColor = { _ in .lightGray }

        // MARK: - Background

        /// General background of the application. Should be something that is in constrast with `text` color.
        public var background: UIColor = .streamWhiteSnow
        public var background1: UIColor = .streamWhiteSmoke
        public var background2: UIColor = .streamGrayGainsboro
        public var background3: UIColor = .streamOverlay
        public var background4: UIColor = .streamOverlayDark
        public var background5: UIColor = .streamOverlayDarkStatic
        public var background6: UIColor = .streamGrayWhisper
        public var background7: UIColor = .streamDarkGray
        public var background8: UIColor = .streamWhite

        public var overlayBackground: UIColor = .streamOverlayLight
        public var popoverBackground: UIColor = .streamWhite
        public var highlightedBackground: UIColor = .streamGrayGainsboro
        public var highlightedAccentBackground: UIColor = .streamAccentBlue
        public var highlightedAccentBackground1: UIColor = .streamBlueAlice

        // MARK: - Borders and shadows

        public var shadow: UIColor = .streamModalShadow
        public var lightBorder: UIColor = .streamWhiteSnow
        public var border: UIColor = .streamGrayGainsboro
        public var border2: UIColor = .streamGray
        public var border3: UIColor = .streamGrayWhisper

        // MARK: - Tint and alert

        public var alert: UIColor = .streamAccentRed
        public var alternativeActiveTint: UIColor = .streamAccentGreen
        public var inactiveTint: UIColor = .streamGray
        public var alternativeInactiveTint: UIColor = .streamGrayGainsboro
    }
}

// Those colors are default defined stream constants, which are fallback values if you don't implement your color theme.
// There is this static method `mode(_ light:, lightAlpha:, _ dark:, darkAlpha:)` which can help you in a great way with
// implementing dark mode support.
private extension UIColor {
    /// This is color palette used by design team.
    /// If you see any color not from this list in figma, point it out to anyone in design team.
    static let streamBlack = mode(0x000000, 0xffffff)
    static let streamGray = mode(0x7a7a7a, 0x7a7a7a)
    static let streamGrayGainsboro = mode(0xdbdbdb, 0x2d2f2f)
    static let streamGrayWhisper = mode(0xecebeb, 0x1c1e22)
    static let streamDarkGray = mode(0x7a7a7a, 0x7a7a7a)
    static let streamWhiteSmoke = mode(0xf2f2f2, 0x13151b)
    static let streamWhiteSnow = mode(0xfcfcfc, 0x070a0d)
    static let streamOverlayLight = mode(0xfcfcfc, lightAlpha: 0.9, 0x070a0d, darkAlpha: 0.9)
    static let streamWhite = mode(0xffffff, 0x101418)
    static let streamBlueAlice = mode(0xe9f2ff, 0x00193d)
    static let streamAccentBlue = mode(0x005fff, 0x005fff)
    static let streamAccentRed = mode(0xff3742, 0xff3742)
    static let streamAccentGreen = mode(0x20e070, 0x20e070)
    
    // Currently we are not using the correct shadow color from figma's color palette. This is to avoid
    // an issue with snapshots inconsistency between Intel vs M1. We can't use shadows with transparency.
    // So we apply a light gray color to fake the transparency.
    static let streamModalShadow = mode(0xd6d6d6, lightAlpha: 1, 0, darkAlpha: 1)

    static let streamWhiteStatic = mode(0xffffff, 0xffffff)

    static let streamBGGradientFrom = mode(0xf7f7f7, 0x101214)
    static let streamBGGradientTo = mode(0xfcfcfc, 0x070a0d)
    static let streamOverlay = mode(0x000000, lightAlpha: 0.2, 0x000000, darkAlpha: 0.4)
    static let streamOverlayDark = mode(0x000000, lightAlpha: 0.6, 0xffffff, darkAlpha: 0.8)
    static let streamOverlayDarkStatic = mode(0x000000, lightAlpha: 0.6, 0x000000, darkAlpha: 0.6)

    static func mode(_ light: Int, lightAlpha: CGFloat = 1.0, _ dark: Int, darkAlpha: CGFloat = 1.0) -> UIColor {
        if #available(iOS 13.0, *) {
            return UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(rgb: dark).withAlphaComponent(darkAlpha)
                    : UIColor(rgb: light).withAlphaComponent(lightAlpha)
            }
        } else {
            return UIColor(rgb: light).withAlphaComponent(lightAlpha)
        }
    }
}
