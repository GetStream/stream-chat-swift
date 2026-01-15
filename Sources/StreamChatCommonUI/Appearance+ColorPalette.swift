//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit

public extension Appearance {
    final class ColorPalette: @unchecked Sendable {
        // MARK: - Text

        /// General textColor, should be something that contrasts great with your `background` Color
        public var text: UIColor = .streamBlack
        public var textInverted: UIColor = .streamWhite
        public var textLowEmphasis: UIColor = .streamGrayDisabledText
        public var textLinkColor: UIColor = .systemBlue

        /// Static color which should stay the same in dark and light mode, because it's only used as text on small UI Elements
        /// such as `ChatUnreadCountView`, `GiphyBadge` or Commands icon.
        public var staticColorText: UIColor = .streamWhiteStatic
        public var staticBlackColorText: UIColor = .streamBlackStatic
        public var subtitleText: UIColor = .streamGray

        // MARK: - Text interactions

        public var highlightedColorForColor: @Sendable (UIColor) -> UIColor = { $0.withAlphaComponent(0.5) }
        public var disabledColorForColor: @Sendable (UIColor) -> UIColor = { _ in .lightGray }
        public var unselectedColorForColor: @Sendable (UIColor) -> UIColor = { _ in .lightGray }

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

        public var messageCellHighlightBackground: UIColor = .streamYellowBackground
        public var pinnedMessageBackground: UIColor = .streamYellowBackground
        public var jumpToUnreadButtonBackground: UIColor = .streamGrayDisabledText

        // MARK: - Borders and shadows

        public var shadow: UIColor = .streamModalShadow
        public var lightBorder: UIColor = .streamWhiteSnow
        public var border: UIColor = .streamGrayGainsboro
        public var border2: UIColor = .streamGray
        public var border3: UIColor = .streamGrayWhisper
        public var hoverButtonShadow: UIColor = .streamIconButtonShadow

        // MARK: - Tint and alert

        public var validationError: UIColor = .streamAccentRed
        public var alert: UIColor = .streamAccentRed
        public var alternativeActiveTint: UIColor = .streamAccentGreen
        public var inactiveTint: UIColor = .streamGray
        public var alternativeInactiveTint: UIColor = .streamGrayGainsboro
        
        // MARK: - SwiftUI SDK

        public var navigationBarTitle: UIColor {
            didSet {
                StreamConcurrency.onMain { [navigationBarTitle] in
                    let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: navigationBarTitle]
                    UINavigationBar.appearance().titleTextAttributes = attributes
                    UINavigationBar.appearance().largeTitleTextAttributes = attributes
                }
            }
        }
               
        public var innerBorder: UIColor = .streamInnerBorder
        
        public var navigationBarSubtitle: UIColor
        
        public var navigationBarBackground: UIColor?
        
        public lazy var reactionCurrentUserColor: UIColor = accentPrimary
        
        public var reactionOtherUserColor: UIColor
        
        public var quotedMessageBackgroundCurrentUser: UIColor
        
        public var quotedMessageBackgroundOtherUser: UIColor
        
        public lazy var navigationBarTintColor: UIColor = accentPrimary
        
        public var composerInputHighlightedBorder: UIColor
        
        public var voiceMessageControlBackground: UIColor = .streamWhiteStatic
        
        public var messageCurrentUserBackground: [UIColor]
        
        public var messageCurrentUserEmphemeralBackground: [UIColor]
        
        public var messageOtherUserBackground: [UIColor]
        
        public var messageCurrentUserTextColor: UIColor
        
        public var messageOtherUserTextColor: UIColor
        
        public var selectedReactionBackgroundColor: UIColor?
        
        public var bannerBackgroundColor: UIColor = .streamDarkGray
        
        public var composerInputBackground: UIColor
        
        public var composerPlaceholderColor: UIColor
        
        public lazy var messageLinkAttachmentAuthorColor: Color = Color(accentPrimary)
        
        public var messageLinkAttachmentTitleColor: Color
        
        public var messageLinkAttachmentTextColor: Color
        
        public var navigationBarGlyph: UIColor
                
        public init() {
            navigationBarGlyph = .white
            navigationBarTitle = text
            navigationBarSubtitle = textLowEmphasis
            reactionOtherUserColor = textLowEmphasis
            quotedMessageBackgroundOtherUser = background8
            quotedMessageBackgroundCurrentUser = background8
            composerInputHighlightedBorder = innerBorder
            messageCurrentUserBackground = [background6]
            messageCurrentUserEmphemeralBackground = [background8]
            messageOtherUserBackground = [background8]
            messageCurrentUserTextColor = text
            messageOtherUserTextColor = text
            composerInputBackground = background
            composerPlaceholderColor = subtitleText
            messageLinkAttachmentTitleColor = Color(text)
            messageLinkAttachmentTextColor = Color(text)
        }
        
        // MARK: - Autogenerated from Tokens
        
        public lazy var accentError: UIColor = UIColor(light: .red500, dark: .red400)
        public lazy var accentNeutral: UIColor = UIColor(light: .slate500, dark: .neutral500)
        public lazy var accentPrimary: UIColor = UIColor(light: .blue500, dark: .blue400)
        public lazy var accentSuccess: UIColor = UIColor(light: .green500, dark: .green400)
        public lazy var accentWarning: UIColor = UIColor(light: .yellow500, dark: .yellow400)
        public lazy var avatarBgDefault: UIColor = avatarPaletteBg1
        public lazy var avatarPaletteBg1: UIColor = UIColor(light: .blue100, dark: .blue800)
        public lazy var avatarPaletteBg2: UIColor = UIColor(light: .cyan100, dark: .cyan800)
        public lazy var avatarPaletteBg3: UIColor = UIColor(light: .green100, dark: .green800)
        public lazy var avatarPaletteBg4: UIColor = UIColor(light: .purple200, dark: .purple800)
        public lazy var avatarPaletteBg5: UIColor = UIColor(light: .yellow200, dark: .yellow800)
        public lazy var avatarPaletteText1: UIColor = UIColor(light: .blue800, dark: .blue100)
        public lazy var avatarPaletteText2: UIColor = UIColor(light: .cyan800, dark: .cyan100)
        public lazy var avatarPaletteText3: UIColor = UIColor(light: .green800, dark: .green100)
        public lazy var avatarPaletteText4: UIColor = UIColor(light: .purple800, dark: .purple100)
        public lazy var avatarPaletteText5: UIColor = UIColor(light: .yellow800, dark: .yellow100)
        public lazy var avatarTextDefault: UIColor = avatarPaletteText1
        public lazy var backgroundCoreApp: UIColor = UIColor(light: .baseWhite, dark: .baseBlack)
        public lazy var backgroundCoreOverlay: UIColor = UIColor(light: UIColor(hex: 0x0000001a), dark: UIColor(hex: 0x00000080))
        public lazy var backgroundCoreSurface: UIColor = UIColor(light: .slate50, dark: .neutral900)
        public lazy var backgroundCoreSurfaceStrong: UIColor = UIColor(light: .slate200, dark: .neutral700)
        public lazy var backgroundCoreSurfaceSubtle: UIColor = UIColor(light: .slate100, dark: .neutral800)
        public lazy var backgroundElevationElevation0: UIColor = UIColor(light: .baseWhite, dark: .baseBlack)
        public lazy var backgroundElevationElevation1: UIColor = UIColor(light: .baseWhite, dark: .neutral900)
        public lazy var backgroundElevationElevation2: UIColor = UIColor(light: .baseWhite, dark: .neutral800)
        public lazy var backgroundElevationElevation3: UIColor = UIColor(light: .baseWhite, dark: .neutral700)
        public lazy var backgroundElevationElevation4: UIColor = UIColor(light: .baseWhite, dark: .neutral600)
        public lazy var badgeBgError: UIColor = colorAccentError
        public lazy var badgeBgInverse: UIColor = .baseWhite
        public lazy var badgeBgNeutral: UIColor = colorAccentNeutral
        public lazy var badgeBgPrimary: UIColor = colorAccentPrimary
        public lazy var badgeBorder: UIColor = UIColor(light: .baseWhite, dark: .baseBlack)
        public lazy var badgeText: UIColor = .baseWhite
        public lazy var badgeTextInverse: UIColor = UIColor(light: .slate900, dark: .neutral50)
        public lazy var borderCoreImage: UIColor = UIColor(light: UIColor(hex: 0x0000001a), dark: UIColor(hex: 0xffffff33))
        public lazy var borderCoreOnAccent: UIColor = .baseWhite
        public lazy var borderCoreOnDark: UIColor = .baseWhite
        public lazy var borderCoreOpacity25: UIColor = UIColor(light: UIColor(hex: 0x00000040), dark: UIColor(hex: 0xffffff40))
        public lazy var borderCorePrimary: UIColor = UIColor(light: .blue600, dark: .blue300)
        public lazy var borderCoreSubtle: UIColor = UIColor(light: .slate100, dark: .neutral800)
        public lazy var borderCoreSurface: UIColor = UIColor(light: .slate400, dark: .neutral500)
        public lazy var borderCoreSurfaceStrong: UIColor = UIColor(light: .slate600, dark: .neutral400)
        public lazy var borderCoreSurfaceSubtle: UIColor = UIColor(light: .slate200, dark: .neutral700)
        public lazy var borderUtilityBorder: UIColor = UIColor(light: .slate100, dark: .neutral800)
        public lazy var borderUtilityError: UIColor = UIColor(light: .red500, dark: .red400)
        public lazy var borderUtilityFocus: UIColor = colorBrand300
        public lazy var borderUtilitySelected: UIColor = UIColor(light: colorBrand500, dark: .baseWhite)
        public lazy var borderUtilitySuccess: UIColor = UIColor(light: .green500, dark: .green400)
        public lazy var borderUtilityWarning: UIColor = UIColor(light: .yellow500, dark: .yellow400)
        public lazy var buttonDestructiveBg: UIColor = colorAccentError
        public lazy var buttonDestructiveBorder: UIColor = colorAccentError
        public lazy var buttonDestructiveText: UIColor = .baseWhite
        public lazy var buttonDestructiveTextInverse: UIColor = colorAccentError
        public lazy var buttonPrimaryBg: UIColor = colorAccentPrimary
        public lazy var buttonPrimaryBorder: UIColor = colorBrand600
        public lazy var buttonPrimaryText: UIColor = textOnAccent
        public lazy var buttonSecondaryBg: UIColor = .baseTransparent0
        public lazy var buttonSecondaryBorder: UIColor = borderCoreSurfaceSubtle
        public lazy var buttonSecondaryText: UIColor = textPrimary
        public lazy var buttonStyleGhostBg: UIColor = .baseTransparent0
        public lazy var buttonStyleGhostBorder: UIColor = .baseTransparent0
        public lazy var buttonStyleGhostTextPrimary: UIColor = colorAccentPrimary
        public lazy var buttonStyleGhostTextSecondary: UIColor = textPrimary
        public lazy var buttonStyleLiquidGlassBgDestructive: UIColor = .baseTransparent0
        public lazy var buttonStyleLiquidGlassBgPrimary: UIColor = .baseTransparent0
        public lazy var buttonStyleLiquidGlassBgSecondary: UIColor = UIColor(light: .baseWhite, dark: .baseBlack)
        public lazy var buttonStyleLiquidGlassTextDestructive: UIColor = .baseWhite
        public lazy var buttonStyleLiquidGlassTextPrimary: UIColor = .baseWhite
        public lazy var buttonStyleLiquidGlassTextSecondary: UIColor = textPrimary
        public lazy var buttonStyleOutlineBg: UIColor = .baseTransparent0
        public lazy var buttonStyleOutlineBorder: UIColor = borderCoreSurfaceSubtle
        public lazy var buttonStyleOutlineBorderOnChatIncoming: UIColor = borderCoreSurface
        public lazy var buttonStyleOutlineBorderOnChatOutgoing: UIColor = UIColor(light: .blue300, dark: borderCoreOnAccent)
        public lazy var buttonStyleOutlineText: UIColor = textPrimary
        public lazy var buttonTypeDestructiveBg: UIColor = accentError
        public lazy var buttonTypeDestructiveBorder: UIColor = accentError
        public lazy var buttonTypeDestructiveText: UIColor = .baseWhite
        public lazy var buttonTypeDestructiveTextInverse: UIColor = accentError
        public lazy var buttonTypePrimaryBg: UIColor = accentPrimary
        public lazy var buttonTypePrimaryBorder: UIColor = borderCorePrimary
        public lazy var buttonTypePrimaryText: UIColor = textOnAccent
        public lazy var buttonTypeSecondaryBg: UIColor = .baseTransparentBase
        public lazy var buttonTypeSecondaryBorder: UIColor = borderCoreSurfaceSubtle
        public lazy var buttonTypeSecondaryText: UIColor = textPrimary
        public lazy var chatBgAttachmentIncoming: UIColor = UIColor(light: .slate200, dark: .neutral700)
        public lazy var chatBgAttachmentOutgoing: UIColor = colorBrand200
        public lazy var chatBgIncoming: UIColor = UIColor(light: .slate100, dark: .neutral800)
        public lazy var chatBgOutgoing: UIColor = UIColor(light: colorBrand100, dark: colorBrand200)
        public lazy var chatBgTypingIndicator: UIColor = UIColor(light: .baseBlack, dark: .baseWhite)
        public lazy var chatBorderIncoming: UIColor = .baseTransparent0
        public lazy var chatBorderOnChatIncoming: UIColor = UIColor(light: .slate500, dark: .slate600)
        public lazy var chatBorderOnChatOutgoing: UIColor = UIColor(light: colorBrand400, dark: colorBrand600)
        public lazy var chatBorderOutgoing: UIColor = .baseTransparent0
        public lazy var chatPollProgressFillIncoming: UIColor = UIColor(light: .slate300, dark: .neutral600)
        public lazy var chatPollProgressFillOutgoing: UIColor = UIColor(light: colorBrand200, dark: colorBrand400)
        public lazy var chatPollProgressTrackIncoming: UIColor = UIColor(light: .slate600, dark: .baseWhite)
        public lazy var chatPollProgressTrackOutgoing: UIColor = UIColor(light: colorAccentPrimary, dark: .baseWhite)
        public lazy var chatReplyIndicatorIncoming: UIColor = UIColor(light: .slate400, dark: .neutral500)
        public lazy var chatReplyIndicatorOutgoing: UIColor = UIColor(light: colorBrand400, dark: colorBrand700)
        public lazy var chatTextLink: UIColor = textLink
        public lazy var chatTextMention: UIColor = textLink
        public lazy var chatTextMessage: UIColor = textPrimary
        public lazy var chatTextReaction: UIColor = textSecondary
        public lazy var chatTextSystem: UIColor = textSecondary
        public lazy var chatTextTimestamp: UIColor = textTertiary
        public lazy var chatTextUsername: UIColor = textSecondary
        public lazy var chatThreadConnectorIncoming: UIColor = UIColor(light: .slate200, dark: chatBgIncoming)
        public lazy var chatThreadConnectorOutgoing: UIColor = chatBgOutgoing
        public lazy var chatWaveformBar: UIColor = borderCoreOpacity25
        public lazy var chatWaveformBarPlaying: UIColor = UIColor(light: colorAccentPrimary, dark: .baseWhite)
        public lazy var colorAccentError: UIColor = UIColor(light: .red500, dark: .red400)
        public lazy var colorAccentNeutral: UIColor = UIColor(light: .slate500, dark: .neutral500)
        public lazy var colorAccentPrimary: UIColor = colorBrand500
        public lazy var colorAccentSuccess: UIColor = UIColor(light: .green500, dark: .green400)
        public lazy var colorAccentWarning: UIColor = UIColor(light: .yellow500, dark: .yellow400)
        public lazy var colorBrand100: UIColor = UIColor(light: .blue100, dark: .blue800)
        public lazy var colorBrand200: UIColor = UIColor(light: .blue200, dark: .blue700)
        public lazy var colorBrand300: UIColor = UIColor(light: .blue300, dark: .blue600)
        public lazy var colorBrand400: UIColor = UIColor(light: .blue400, dark: .blue500)
        public lazy var colorBrand50: UIColor = UIColor(light: .blue50, dark: .blue900)
        public lazy var colorBrand500: UIColor = UIColor(light: .blue500, dark: .blue400)
        public lazy var colorBrand600: UIColor = UIColor(light: .blue600, dark: .blue300)
        public lazy var colorBrand700: UIColor = UIColor(light: .blue700, dark: .blue200)
        public lazy var colorBrand800: UIColor = UIColor(light: .blue800, dark: .blue100)
        public lazy var colorBrand900: UIColor = UIColor(light: .blue900, dark: .blue50)
        public lazy var colorBrand950: UIColor = UIColor(light: .blue950, dark: .baseWhite)
        public lazy var colorStateBgDisabled: UIColor = UIColor(light: .slate200, dark: .neutral800)
        public lazy var colorStateBgOverlay: UIColor = UIColor(hex: 0x00000080)
        public lazy var colorStateHover: UIColor = UIColor(hex: 0x0000000d)
        public lazy var colorStatePressed: UIColor = UIColor(hex: 0x0000001a)
        public lazy var colorStateSelected: UIColor = UIColor(hex: 0x0000001a)
        public lazy var colorStateTextDisabled: UIColor = UIColor(light: .slate400, dark: .neutral600)
        public lazy var composerBg: UIColor = backgroundElevationElevation1
        public lazy var controlProgressBarFill: UIColor = UIColor(light: .slate100, dark: .neutral800)
        public lazy var controlProgressBarTrack: UIColor = UIColor(light: .slate500, dark: .neutral500)
        public lazy var controlRadiocheckBg: UIColor = .baseTransparent0
        public lazy var controlRadiocheckBgDisabled: UIColor = .baseTransparent0
        public lazy var controlRadiocheckBgSelected: UIColor = UIColor(light: colorAccentPrimary, dark: .baseWhite)
        public lazy var controlRadiocheckBgSelectedDisabled: UIColor = colorStateBgDisabled
        public lazy var controlRadiocheckBorder: UIColor = borderCoreSurfaceSubtle
        public lazy var controlRadiocheckBorderDisabled: UIColor = borderUtilityBorder
        public lazy var controlRadiocheckBorderSelected: UIColor = UIColor(light: borderUtilitySelected, dark: .baseWhite)
        public lazy var controlRadiocheckIconSelected: UIColor = textInverse
        public lazy var controlRadiocheckIconSelectedDisabled: UIColor = colorStateTextDisabled
        public lazy var controlRemoveBg: UIColor = UIColor(light: .slate900, dark: .neutral800)
        public lazy var controlRemoveBorder: UIColor = borderCoreOnDark
        public lazy var controlRemoveIcon: UIColor = .baseWhite
        public lazy var inputBgBgDisabled: UIColor = UIColor(light: colorStateBgDisabled, dark: colorStateHover)
        public lazy var inputBgDefault: UIColor = .baseTransparent0
        public lazy var inputBgHover: UIColor = colorStateHover
        public lazy var inputBorderBorderDisabled: UIColor = borderCoreSubtle
        public lazy var inputBorderDefault: UIColor = borderCoreSurfaceSubtle
        public lazy var inputBorderFocus: UIColor = borderUtilityFocus
        public lazy var inputBorderHover: UIColor = borderCoreSurface
        public lazy var inputSendIcon: UIColor = colorAccentPrimary
        public lazy var inputSendIconDisabled: UIColor = colorStateTextDisabled
        public lazy var inputTextDefault: UIColor = UIColor(light: .slate900, dark: .neutral50)
        public lazy var inputTextDisabled: UIColor = UIColor(light: .slate400, dark: .neutral600)
        public lazy var inputTextIcon: UIColor = UIColor(light: .slate700, dark: .neutral300)
        public lazy var inputTextPlaceholder: UIColor = UIColor(light: .slate600, dark: .neutral400)
        public lazy var presenceBgOffline: UIColor = colorAccentNeutral
        public lazy var presenceBgOnline: UIColor = colorAccentSuccess
        public lazy var presenceBorder: UIColor = UIColor(light: .baseWhite, dark: .baseBlack)
        public lazy var reactionBg: UIColor = backgroundElevationElevation1
        public lazy var reactionBorder: UIColor = borderCoreSurfaceSubtle
        public lazy var reactionEmoji: UIColor = textPrimary
        public lazy var reactionText: UIColor = textPrimary
        public lazy var stateBgDisabled: UIColor = UIColor(light: .slate200, dark: .neutral800)
        public lazy var stateBgOverlay: UIColor = UIColor(hex: 0x00000080)
        public lazy var stateHover: UIColor = UIColor(hex: 0x0000000d)
        public lazy var statePressed: UIColor = UIColor(hex: 0x0000001a)
        public lazy var stateSelected: UIColor = UIColor(hex: 0x0000001a)
        public lazy var stateTextDisabled: UIColor = UIColor(light: .slate400, dark: .neutral600)
        public lazy var systemBgBlur: UIColor = UIColor(light: UIColor(hex: 0xffffff03), dark: UIColor(hex: 0x00000003))
        public lazy var systemScrollbar: UIColor = UIColor(light: UIColor(hex: 0x00000080), dark: UIColor(hex: 0xffffff80))
        public lazy var systemText: UIColor = UIColor(light: .baseBlack, dark: .baseWhite)
        public lazy var textDisabled: UIColor = UIColor(light: .slate400, dark: .neutral600)
        public lazy var textInverse: UIColor = UIColor(light: .baseWhite, dark: .baseBlack)
        public lazy var textLink: UIColor = colorAccentPrimary
        public lazy var textOnAccent: UIColor = .baseWhite
        public lazy var textPrimary: UIColor = UIColor(light: .slate900, dark: .neutral50)
        public lazy var textSecondary: UIColor = UIColor(light: .slate700, dark: .neutral300)
        public lazy var textTertiary: UIColor = UIColor(light: .slate600, dark: .neutral400)
    }
}

// Those colors are default defined stream constants, which are fallback values if you don't implement your color theme.
// There is this static method `mode(_ light:, lightAlpha:, _ dark:, darkAlpha:)` which can help you in a great way with
// implementing dark mode support.
private extension UIColor {
    static let streamAccentPrimary = mode(0x005fff, 0x337eff)

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
    static let streamGrayDisabledText = mode(0x72767e, 0x72767e)
    static let streamInnerBorder = mode(0xdbdde1, 0x272a30)
    static let streamYellowBackground = mode(0xfbf4dd, 0x333024)

    // Currently we are not using the correct shadow color from figma's color palette. This is to avoid
    // an issue with snapshots inconsistency between Intel vs M1. We can't use shadows with transparency.
    // So we apply a light gray color to fake the transparency.
    static let streamModalShadow = mode(0xd6d6d6, lightAlpha: 1, 0, darkAlpha: 1)

    static let streamWhiteStatic = mode(0xffffff, 0xffffff)
    static let streamBlackStatic = mode(0x000000, 0x000000)

    static let streamBGGradientFrom = mode(0xf7f7f7, 0x101214)
    static let streamBGGradientTo = mode(0xfcfcfc, 0x070a0d)
    static let streamOverlay = mode(0x000000, lightAlpha: 0.2, 0x000000, darkAlpha: 0.4)
    static let streamOverlayDark = mode(0x000000, lightAlpha: 0.6, 0xffffff, darkAlpha: 0.8)
    static let streamOverlayDarkStatic = mode(0x000000, lightAlpha: 0.6, 0x000000, darkAlpha: 0.6)
    static let streamIconButtonShadow = mode(0x000000, lightAlpha: 0.25, 0x000000, darkAlpha: 0.25)

    static func mode(_ light: Int, lightAlpha: CGFloat = 1.0, _ dark: Int, darkAlpha: CGFloat = 1.0) -> UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(rgb: dark).withAlphaComponent(darkAlpha)
                : UIColor(rgb: light).withAlphaComponent(lightAlpha)
        }
    }
}

// MARK: - Autogenerated from Tokens

extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 24) & 0xff) / 255.0
        let g = CGFloat((hex >> 16) & 0xff) / 255.0
        let b = CGFloat((hex >> 8) & 0xff) / 255.0
        let a = CGFloat(hex & 0xff) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    convenience init(light: UIColor, dark: UIColor) {
        self.init { trait in
            return trait.userInterfaceStyle == .dark ? dark : light
        }
    }

    static let baseBlack: UIColor = UIColor(hex: 0x000000ff)
    static let baseTransparent0: UIColor = UIColor(hex: 0xffffff03)
    static let baseTransparentBase: UIColor = UIColor(hex: 0xffffff00)
    static let baseTransparentBlack10: UIColor = UIColor(hex: 0x0000001a)
    static let baseTransparentBlack5: UIColor = UIColor(hex: 0x0000000d)
    static let baseWhite: UIColor = UIColor(hex: 0xffffffff)
    static let blue100: UIColor = UIColor(hex: 0xd2e3ffff)
    static let blue200: UIColor = UIColor(hex: 0xa6c4ffff)
    static let blue300: UIColor = UIColor(hex: 0x7aa7ffff)
    static let blue400: UIColor = UIColor(hex: 0x4e8bffff)
    static let blue50: UIColor = UIColor(hex: 0xebf3ffff)
    static let blue500: UIColor = UIColor(hex: 0x005fffff)
    static let blue600: UIColor = UIColor(hex: 0x0052ceff)
    static let blue700: UIColor = UIColor(hex: 0x0042a3ff)
    static let blue800: UIColor = UIColor(hex: 0x003179ff)
    static let blue900: UIColor = UIColor(hex: 0x001f4fff)
    static let blue950: UIColor = UIColor(hex: 0x001025ff)
    static let cyan100: UIColor = UIColor(hex: 0xd7f7fbff)
    static let cyan200: UIColor = UIColor(hex: 0xbdf1f8ff)
    static let cyan300: UIColor = UIColor(hex: 0xa3ecf4ff)
    static let cyan400: UIColor = UIColor(hex: 0x89e6f1ff)
    static let cyan50: UIColor = UIColor(hex: 0xf0fcfeff)
    static let cyan500: UIColor = UIColor(hex: 0x69e5f6ff)
    static let cyan600: UIColor = UIColor(hex: 0x3ec9d9ff)
    static let cyan700: UIColor = UIColor(hex: 0x28a8b5ff)
    static let cyan800: UIColor = UIColor(hex: 0x1c8791ff)
    static let cyan900: UIColor = UIColor(hex: 0x125f66ff)
    static let cyan950: UIColor = UIColor(hex: 0x0b3d44ff)
    static let green100: UIColor = UIColor(hex: 0xc9fce7ff)
    static let green200: UIColor = UIColor(hex: 0xa9f8d9ff)
    static let green300: UIColor = UIColor(hex: 0x88f2caff)
    static let green400: UIColor = UIColor(hex: 0x59e9b5ff)
    static let green50: UIColor = UIColor(hex: 0xe8fff5ff)
    static let green500: UIColor = UIColor(hex: 0x00e2a1ff)
    static let green600: UIColor = UIColor(hex: 0x00b681ff)
    static let green700: UIColor = UIColor(hex: 0x008d64ff)
    static let green800: UIColor = UIColor(hex: 0x006548ff)
    static let green900: UIColor = UIColor(hex: 0x003d2bff)
    static let green950: UIColor = UIColor(hex: 0x002319ff)
    static let neutral100: UIColor = UIColor(hex: 0xedededff)
    static let neutral200: UIColor = UIColor(hex: 0xd9d9d9ff)
    static let neutral300: UIColor = UIColor(hex: 0xc1c1c1ff)
    static let neutral400: UIColor = UIColor(hex: 0xa3a3a3ff)
    static let neutral50: UIColor = UIColor(hex: 0xf7f7f7ff)
    static let neutral500: UIColor = UIColor(hex: 0x7f7f7fff)
    static let neutral600: UIColor = UIColor(hex: 0x636363ff)
    static let neutral700: UIColor = UIColor(hex: 0x4a4a4aff)
    static let neutral800: UIColor = UIColor(hex: 0x383838ff)
    static let neutral900: UIColor = UIColor(hex: 0x262626ff)
    static let neutral950: UIColor = UIColor(hex: 0x151515ff)
    static let purple100: UIColor = UIColor(hex: 0xebdefdff)
    static let purple200: UIColor = UIColor(hex: 0xd8bffcff)
    static let purple300: UIColor = UIColor(hex: 0xc79ffcff)
    static let purple400: UIColor = UIColor(hex: 0xb98af9ff)
    static let purple50: UIColor = UIColor(hex: 0xf5effeff)
    static let purple500: UIColor = UIColor(hex: 0xb38af8ff)
    static let purple600: UIColor = UIColor(hex: 0x996ce3ff)
    static let purple700: UIColor = UIColor(hex: 0x7f55c7ff)
    static let purple800: UIColor = UIColor(hex: 0x6640abff)
    static let purple900: UIColor = UIColor(hex: 0x4d2c8fff)
    static let purple950: UIColor = UIColor(hex: 0x351c6bff)
    static let red100: UIColor = UIColor(hex: 0xf8cfcdff)
    static let red200: UIColor = UIColor(hex: 0xf3b3b0ff)
    static let red300: UIColor = UIColor(hex: 0xed958fff)
    static let red400: UIColor = UIColor(hex: 0xe6756cff)
    static let red50: UIColor = UIColor(hex: 0xfcebeaff)
    static let red500: UIColor = UIColor(hex: 0xd92f26ff)
    static let red600: UIColor = UIColor(hex: 0xb9261fff)
    static let red700: UIColor = UIColor(hex: 0x98201aff)
    static let red800: UIColor = UIColor(hex: 0x761915ff)
    static let red900: UIColor = UIColor(hex: 0x54120fff)
    static let red950: UIColor = UIColor(hex: 0x360b09ff)
    static let slate100: UIColor = UIColor(hex: 0xf2f4f6ff)
    static let slate200: UIColor = UIColor(hex: 0xe2e6eaff)
    static let slate300: UIColor = UIColor(hex: 0xd0d5daff)
    static let slate400: UIColor = UIColor(hex: 0xb8bec4ff)
    static let slate50: UIColor = UIColor(hex: 0xfafbfcff)
    static let slate500: UIColor = UIColor(hex: 0x9ea4aaff)
    static let slate600: UIColor = UIColor(hex: 0x838990ff)
    static let slate700: UIColor = UIColor(hex: 0x6a7077ff)
    static let slate800: UIColor = UIColor(hex: 0x50565dff)
    static let slate900: UIColor = UIColor(hex: 0x384047ff)
    static let slate950: UIColor = UIColor(hex: 0x1e252bff)
    static let yellow100: UIColor = UIColor(hex: 0xfff1c2ff)
    static let yellow200: UIColor = UIColor(hex: 0xffe8a0ff)
    static let yellow300: UIColor = UIColor(hex: 0xffde7dff)
    static let yellow400: UIColor = UIColor(hex: 0xffd65aff)
    static let yellow50: UIColor = UIColor(hex: 0xfff9e5ff)
    static let yellow500: UIColor = UIColor(hex: 0xffd233ff)
    static let yellow600: UIColor = UIColor(hex: 0xe6b400ff)
    static let yellow700: UIColor = UIColor(hex: 0xc59600ff)
    static let yellow800: UIColor = UIColor(hex: 0x9f7700ff)
    static let yellow900: UIColor = UIColor(hex: 0x7a5a00ff)
    static let yellow950: UIColor = UIColor(hex: 0x4f3900ff)
}

extension UIColor {
    /// The color represented as SwiftUI color.
    public var toColor: Color {
        Color(self)
    }
}
