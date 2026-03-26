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
        public lazy var accentNeutral: UIColor = chrome500
        public lazy var accentPrimary: UIColor = UIColor(light: brand500, dark: brand400)
        public lazy var accentSuccess: UIColor = UIColor(light: .green400, dark: .green300)
        public lazy var accentWarning: UIColor = UIColor(light: .yellow400, dark: .yellow300)
        public lazy var avatarBackgroundDefault: UIColor = avatarPaletteBackground1
        public lazy var avatarBackgroundPlaceholder: UIColor = chrome150
        public lazy var avatarPaletteBackground1: UIColor = UIColor(light: .blue150, dark: .blue600)
        public lazy var avatarPaletteBackground2: UIColor = UIColor(light: .cyan150, dark: .cyan600)
        public lazy var avatarPaletteBackground3: UIColor = UIColor(light: .green150, dark: .green600)
        public lazy var avatarPaletteBackground4: UIColor = UIColor(light: .purple150, dark: .purple600)
        public lazy var avatarPaletteBackground5: UIColor = UIColor(light: .yellow150, dark: .yellow600)
        public lazy var avatarPaletteText1: UIColor = UIColor(light: .blue900, dark: .blue100)
        public lazy var avatarPaletteText2: UIColor = UIColor(light: .cyan900, dark: .cyan100)
        public lazy var avatarPaletteText3: UIColor = UIColor(light: .green900, dark: .green100)
        public lazy var avatarPaletteText4: UIColor = UIColor(light: .purple900, dark: .purple100)
        public lazy var avatarPaletteText5: UIColor = UIColor(light: .yellow900, dark: .yellow100)
        public lazy var avatarPresenceBackgroundOffline: UIColor = accentNeutral
        public lazy var avatarPresenceBackgroundOnline: UIColor = accentSuccess
        public lazy var avatarPresenceBorder: UIColor = borderCoreOnInverse
        public lazy var avatarTextDefault: UIColor = avatarPaletteText1
        public lazy var avatarTextPlaceholder: UIColor = chrome500
        public lazy var backgroundCoreApp: UIColor = chrome0
        public lazy var backgroundCoreHighlight: UIColor = UIColor(light: .yellow50, dark: .yellow800)
        public lazy var backgroundCoreInverse: UIColor = chrome1000
        public lazy var backgroundCoreOnAccent: UIColor = UIColor(light: chrome0, dark: chrome1000)
        public lazy var backgroundCoreOverlayDark: UIColor = UIColor(light: UIColor(hex: 0x1a1b2540), dark: UIColor(hex: 0x00000080))
        public lazy var backgroundCoreOverlayLight: UIColor = UIColor(light: UIColor(hex: 0xffffffbf), dark: UIColor(hex: 0x000000bf))
        public lazy var backgroundCoreScrim: UIColor = UIColor(light: UIColor(hex: 0x1a1b2580), dark: UIColor(hex: 0x000000bf))
        public lazy var backgroundCoreSurfaceCard: UIColor = UIColor(light: chrome50, dark: chrome100)
        public lazy var backgroundCoreSurfaceDefault: UIColor = chrome100
        public lazy var backgroundCoreSurfaceStrong: UIColor = chrome150
        public lazy var backgroundCoreSurfaceSubtle: UIColor = chrome50
        public lazy var backgroundElevation0: UIColor = chrome0
        public lazy var backgroundElevation1: UIColor = UIColor(light: chrome0, dark: chrome50)
        public lazy var backgroundElevation2: UIColor = UIColor(light: chrome0, dark: chrome100)
        public lazy var backgroundElevation3: UIColor = UIColor(light: chrome0, dark: chrome200)
        public lazy var backgroundUtilityDisabled: UIColor = chrome100
        public lazy var backgroundUtilityHover: UIColor = UIColor(light: UIColor(hex: 0x1a1b251a), dark: UIColor(hex: 0xffffff26))
        public lazy var backgroundUtilityPressed: UIColor = UIColor(light: UIColor(hex: 0x1a1b2526), dark: UIColor(hex: 0xffffff33))
        public lazy var backgroundUtilitySelected: UIColor = UIColor(light: UIColor(hex: 0x1a1b2533), dark: UIColor(hex: 0xffffff40))
        public lazy var badgeBackgroundDefault: UIColor = backgroundElevation3
        public lazy var badgeBackgroundError: UIColor = accentError
        public lazy var badgeBackgroundInverse: UIColor = chrome1000
        public lazy var badgeBackgroundNeutral: UIColor = accentNeutral
        public lazy var badgeBackgroundOverlay: UIColor = UIColor(hex: 0x000000bf)
        public lazy var badgeBackgroundPrimary: UIColor = accentPrimary
        public lazy var badgeBorder: UIColor = borderCoreOnInverse
        public lazy var badgeText: UIColor = textPrimary
        public lazy var badgeTextOnAccent: UIColor = textOnAccent
        public lazy var badgeTextOnInverse: UIColor = textOnInverse
        public lazy var borderCoreDefault: UIColor = UIColor(light: chrome150, dark: chrome200)
        public lazy var borderCoreInverse: UIColor = chrome0
        public lazy var borderCoreOnAccent: UIColor = UIColor(light: chrome0, dark: chrome1000)
        public lazy var borderCoreOnInverse: UIColor = chrome0
        public lazy var borderCoreOnSurface: UIColor = .slate200
        public lazy var borderCoreOpacityStrong: UIColor = UIColor(light: UIColor(hex: 0x1a1b2540), dark: UIColor(hex: 0xffffff40))
        public lazy var borderCoreOpacitySubtle: UIColor = UIColor(light: UIColor(hex: 0x1a1b251a), dark: UIColor(hex: 0xffffff33))
        public lazy var borderCoreStrong: UIColor = chrome300
        public lazy var borderCoreSubtle: UIColor = chrome100
        public lazy var borderUtilityActive: UIColor = accentPrimary
        public lazy var borderUtilityDisabled: UIColor = chrome100
        public lazy var borderUtilityError: UIColor = accentError
        public lazy var borderUtilityFocus: UIColor = UIColor(hex: 0x78a8ff40)
        public lazy var borderUtilityFocused: UIColor = brand150
        public lazy var borderUtilityHover: UIColor = UIColor(light: UIColor(hex: 0x1a1b251a), dark: UIColor(hex: 0xffffff1a))
        public lazy var borderUtilityPressed: UIColor = UIColor(light: UIColor(hex: 0x1a1b2533), dark: UIColor(hex: 0xffffff33))
        public lazy var borderUtilitySelected: UIColor = UIColor(light: UIColor(hex: 0x1a1b2526), dark: UIColor(hex: 0xffffff26))
        public lazy var borderUtilitySuccess: UIColor = accentSuccess
        public lazy var borderUtilityWarning: UIColor = accentWarning
        lazy var brand100: UIColor = UIColor(light: .blue100, dark: .blue800)
        lazy var brand150: UIColor = UIColor(light: .blue150, dark: .blue700)
        lazy var brand200: UIColor = UIColor(light: .blue200, dark: .blue600)
        lazy var brand300: UIColor = UIColor(light: .blue300, dark: .blue500)
        lazy var brand400: UIColor = .blue400
        lazy var brand50: UIColor = UIColor(light: .blue50, dark: .blue900)
        lazy var brand500: UIColor = UIColor(light: .blue500, dark: .blue300)
        lazy var brand600: UIColor = UIColor(light: .blue600, dark: .blue200)
        lazy var brand700: UIColor = UIColor(light: .blue700, dark: .blue150)
        lazy var brand800: UIColor = UIColor(light: .blue800, dark: .blue100)
        lazy var brand900: UIColor = UIColor(light: .blue900, dark: .blue50)
        public lazy var buttonDestructiveBackground: UIColor = accentError
        public lazy var buttonDestructiveBackgroundLiquidGlass: UIColor = backgroundElevation0
        public lazy var buttonDestructiveBorder: UIColor = accentError
        public lazy var buttonDestructiveBorderOnDark: UIColor = textOnInverse
        public lazy var buttonDestructiveText: UIColor = accentError
        public lazy var buttonDestructiveTextOnAccent: UIColor = textOnAccent
        public lazy var buttonDestructiveTextOnDark: UIColor = textOnInverse
        public lazy var buttonPrimaryBackground: UIColor = accentPrimary
        public lazy var buttonPrimaryBackgroundLiquidGlass: UIColor = .baseTransparent0
        public lazy var buttonPrimaryBorder: UIColor = brand200
        public lazy var buttonPrimaryBorderOnDark: UIColor = UIColor(light: borderCoreOnInverse, dark: textOnInverse)
        public lazy var buttonPrimaryText: UIColor = textLink
        public lazy var buttonPrimaryTextOnAccent: UIColor = textOnAccent
        public lazy var buttonPrimaryTextOnDark: UIColor = textOnInverse
        public lazy var buttonSecondaryBackground: UIColor = backgroundCoreSurfaceDefault
        public lazy var buttonSecondaryBackgroundLiquidGlass: UIColor = backgroundElevation0
        public lazy var buttonSecondaryBorder: UIColor = borderCoreDefault
        public lazy var buttonSecondaryBorderOnDark: UIColor = borderCoreOnInverse
        public lazy var buttonSecondaryText: UIColor = textPrimary
        public lazy var buttonSecondaryTextOnAccent: UIColor = textPrimary
        public lazy var buttonSecondaryTextOnDark: UIColor = textOnInverse
        public lazy var chatBackgroundAttachmentIncoming: UIColor = backgroundCoreSurfaceStrong
        public lazy var chatBackgroundAttachmentOutgoing: UIColor = brand150
        public lazy var chatBackgroundIncoming: UIColor = backgroundCoreSurfaceDefault
        public lazy var chatBackgroundOutgoing: UIColor = brand100
        public lazy var chatBorderIncoming: UIColor = borderCoreSubtle
        public lazy var chatBorderOnChatIncoming: UIColor = borderCoreStrong
        public lazy var chatBorderOnChatOutgoing: UIColor = brand300
        public lazy var chatBorderOutgoing: UIColor = brand100
        public lazy var chatPollProgressFillIncoming: UIColor = controlProgressBarFill
        public lazy var chatPollProgressFillOutgoing: UIColor = accentPrimary
        public lazy var chatPollProgressTrackIncoming: UIColor = controlProgressBarTrack
        public lazy var chatPollProgressTrackOutgoing: UIColor = brand200
        public lazy var chatReplyIndicatorIncoming: UIColor = chrome400
        public lazy var chatReplyIndicatorOutgoing: UIColor = brand400
        public lazy var chatTextIncoming: UIColor = textPrimary
        public lazy var chatTextLink: UIColor = textLink
        public lazy var chatTextMention: UIColor = textLink
        public lazy var chatTextOutgoing: UIColor = brand900
        public lazy var chatTextReaction: UIColor = textSecondary
        public lazy var chatTextRead: UIColor = accentPrimary
        public lazy var chatTextSystem: UIColor = textSecondary
        public lazy var chatTextTimestamp: UIColor = textTertiary
        public lazy var chatTextTypingIndicator: UIColor = chatTextIncoming
        public lazy var chatTextUsername: UIColor = textSecondary
        public lazy var chatThreadConnectorIncoming: UIColor = borderCoreDefault
        public lazy var chatThreadConnectorOutgoing: UIColor = brand150
        public lazy var chatWaveformBar: UIColor = borderCoreOpacityStrong
        public lazy var chatWaveformBarPlaying: UIColor = accentPrimary
        lazy var chrome0: UIColor = UIColor(light: .baseWhite, dark: .baseBlack)
        lazy var chrome100: UIColor = UIColor(light: .slate100, dark: .neutral800)
        lazy var chrome1000: UIColor = UIColor(light: .baseBlack, dark: .baseWhite)
        lazy var chrome150: UIColor = UIColor(light: .slate150, dark: .neutral700)
        lazy var chrome200: UIColor = UIColor(light: .slate200, dark: .neutral600)
        lazy var chrome300: UIColor = UIColor(light: .slate300, dark: .neutral500)
        lazy var chrome400: UIColor = UIColor(light: .slate400, dark: .neutral400)
        lazy var chrome50: UIColor = UIColor(light: .slate50, dark: .neutral900)
        lazy var chrome500: UIColor = UIColor(light: .slate500, dark: .neutral300)
        lazy var chrome600: UIColor = UIColor(light: .slate600, dark: .neutral200)
        lazy var chrome700: UIColor = UIColor(light: .slate700, dark: .neutral150)
        lazy var chrome800: UIColor = UIColor(light: .slate800, dark: .neutral100)
        lazy var chrome900: UIColor = UIColor(light: .slate900, dark: .neutral50)
        public lazy var controlCheckboxBackground: UIColor = .baseTransparent0
        public lazy var controlCheckboxBackgroundSelected: UIColor = accentPrimary
        public lazy var controlCheckboxBorder: UIColor = borderCoreDefault
        public lazy var controlCheckboxIcon: UIColor = textOnAccent
        public lazy var controlChipBorder: UIColor = borderCoreDefault
        public lazy var controlChipText: UIColor = textPrimary
        public lazy var controlPlaybackThumbBackgroundActive: UIColor = accentPrimary
        public lazy var controlPlaybackThumbBackgroundDefault: UIColor = backgroundCoreOnAccent
        public lazy var controlPlaybackThumbBorderActive: UIColor = borderCoreOnAccent
        public lazy var controlPlaybackThumbBorderDefault: UIColor = borderCoreOpacityStrong
        public lazy var controlPlaybackToggleBorder: UIColor = borderCoreDefault
        public lazy var controlPlaybackToggleText: UIColor = textPrimary
        public lazy var controlPlayButtonBackground: UIColor = UIColor(hex: 0x000000bf)
        public lazy var controlPlayButtonIcon: UIColor = textOnAccent
        public lazy var controlProgressBarFill: UIColor = accentNeutral
        public lazy var controlProgressBarTrack: UIColor = backgroundCoreSurfaceStrong
        public lazy var controlRadioButtonBackground: UIColor = .baseTransparent0
        public lazy var controlRadioButtonBackgroundSelected: UIColor = accentPrimary
        public lazy var controlRadioButtonBorder: UIColor = borderCoreDefault
        public lazy var controlRadioButtonIndicator: UIColor = textOnAccent
        public lazy var controlRadioCheckBackground: UIColor = .baseTransparent0
        public lazy var controlRadioCheckBackgroundSelected: UIColor = accentPrimary
        public lazy var controlRadioCheckBorder: UIColor = borderCoreDefault
        public lazy var controlRadioCheckIcon: UIColor = textOnAccent
        public lazy var controlRemoveControlBackground: UIColor = backgroundCoreInverse
        public lazy var controlRemoveControlBorder: UIColor = borderCoreOnInverse
        public lazy var controlRemoveControlIcon: UIColor = textOnInverse
        public lazy var controlToggleSwitchBackground: UIColor = accentNeutral
        public lazy var controlToggleSwitchBackgroundDisabled: UIColor = backgroundUtilityDisabled
        public lazy var controlToggleSwitchBackgroundSelected: UIColor = accentPrimary
        public lazy var controlToggleSwitchKnob: UIColor = backgroundCoreOnAccent
        public lazy var inputSendIcon: UIColor = accentPrimary
        public lazy var inputSendIconDisabled: UIColor = textDisabled
        public lazy var inputTextDefault: UIColor = textPrimary
        public lazy var inputTextDisabled: UIColor = textDisabled
        public lazy var inputTextIcon: UIColor = textTertiary
        public lazy var inputTextPlaceholder: UIColor = textTertiary
        public lazy var presenceBackgroundOffline: UIColor = accentNeutral
        public lazy var presenceBackgroundOnline: UIColor = accentSuccess
        public lazy var presenceBorder: UIColor = borderCoreInverse
        public lazy var reactionBackground: UIColor = backgroundElevation3
        public lazy var reactionBorder: UIColor = borderCoreDefault
        public lazy var reactionEmoji: UIColor = textPrimary
        public lazy var reactionText: UIColor = textPrimary
        public lazy var skeletonLoadingBase: UIColor = .baseTransparent0
        public lazy var skeletonLoadingHighlight: UIColor = backgroundCoreOverlayLight
        public lazy var systemBackgroundBlur: UIColor = UIColor(light: UIColor(hex: 0xffffff03), dark: UIColor(hex: 0x00000003))
        public lazy var systemCaret: UIColor = accentPrimary
        public lazy var systemScrollbar: UIColor = UIColor(light: UIColor(hex: 0x00000080), dark: UIColor(hex: 0xffffff80))
        public lazy var systemText: UIColor = chrome1000
        public lazy var textDisabled: UIColor = chrome300
        public lazy var textLink: UIColor = UIColor(light: brand500, dark: brand600)
        public lazy var textOnAccent: UIColor = UIColor(light: chrome0, dark: chrome1000)
        public lazy var textOnInverse: UIColor = chrome0
        public lazy var textPrimary: UIColor = chrome900
        public lazy var textSecondary: UIColor = chrome700
        public lazy var textTertiary: UIColor = chrome500
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
    static let baseTransparent0: UIColor = UIColor(hex: 0xffffff00)
    static let baseTransparentBlack10: UIColor = UIColor(hex: 0x0000001a)
    static let baseTransparentBlack5: UIColor = UIColor(hex: 0x0000000d)
    static let baseTransparentBlack70: UIColor = UIColor(hex: 0x000000b3)
    static let baseTransparentWhite10: UIColor = UIColor(hex: 0xffffff1a)
    static let baseTransparentWhite20: UIColor = UIColor(hex: 0xffffff33)
    static let baseTransparentWhite30: UIColor = UIColor(hex: 0xffffff4d)
    static let baseTransparentWhite70: UIColor = UIColor(hex: 0xffffffb3)
    static let baseWhite: UIColor = UIColor(hex: 0xffffffff)
    static let blue100: UIColor = UIColor(hex: 0xe3edffff)
    static let blue150: UIColor = UIColor(hex: 0xc3d9ffff)
    static let blue200: UIColor = UIColor(hex: 0xa5c5ffff)
    static let blue300: UIColor = UIColor(hex: 0x78a8ffff)
    static let blue400: UIColor = UIColor(hex: 0x4586ffff)
    static let blue50: UIColor = UIColor(hex: 0xf3f7ffff)
    static let blue500: UIColor = UIColor(hex: 0x005fffff)
    static let blue600: UIColor = UIColor(hex: 0x1b53bdff)
    static let blue700: UIColor = UIColor(hex: 0x19418dff)
    static let blue800: UIColor = UIColor(hex: 0x142f63ff)
    static let blue900: UIColor = UIColor(hex: 0x091a3bff)
    static let cyan100: UIColor = UIColor(hex: 0xd1f3f6ff)
    static let cyan150: UIColor = UIColor(hex: 0xa9e4eaff)
    static let cyan200: UIColor = UIColor(hex: 0x72d7e0ff)
    static let cyan300: UIColor = UIColor(hex: 0x45bcc7ff)
    static let cyan400: UIColor = UIColor(hex: 0x1e9ea9ff)
    static let cyan50: UIColor = UIColor(hex: 0xf1fbfcff)
    static let cyan500: UIColor = UIColor(hex: 0x248088ff)
    static let cyan600: UIColor = UIColor(hex: 0x006970ff)
    static let cyan700: UIColor = UIColor(hex: 0x065056ff)
    static let cyan800: UIColor = UIColor(hex: 0x003a3fff)
    static let cyan900: UIColor = UIColor(hex: 0x002124ff)
    static let green100: UIColor = UIColor(hex: 0xbdfcdbff)
    static let green150: UIColor = UIColor(hex: 0x8febbdff)
    static let green200: UIColor = UIColor(hex: 0x59dea3ff)
    static let green300: UIColor = UIColor(hex: 0x00c384ff)
    static let green400: UIColor = UIColor(hex: 0x00a46eff)
    static let green50: UIColor = UIColor(hex: 0xe1ffeeff)
    static let green500: UIColor = UIColor(hex: 0x277e59ff)
    static let green600: UIColor = UIColor(hex: 0x006643ff)
    static let green700: UIColor = UIColor(hex: 0x004f33ff)
    static let green800: UIColor = UIColor(hex: 0x003a25ff)
    static let green900: UIColor = UIColor(hex: 0x002213ff)
    static let lime100: UIColor = UIColor(hex: 0xd4ffb0ff)
    static let lime150: UIColor = UIColor(hex: 0xb1ee79ff)
    static let lime200: UIColor = UIColor(hex: 0x9cda5dff)
    static let lime300: UIColor = UIColor(hex: 0x78c100ff)
    static let lime400: UIColor = UIColor(hex: 0x639e11ff)
    static let lime50: UIColor = UIColor(hex: 0xf1fde8ff)
    static let lime500: UIColor = UIColor(hex: 0x4b7a0aff)
    static let lime600: UIColor = UIColor(hex: 0x3e6213ff)
    static let lime700: UIColor = UIColor(hex: 0x355315ff)
    static let lime800: UIColor = UIColor(hex: 0x203a00ff)
    static let lime900: UIColor = UIColor(hex: 0x112100ff)
    static let neutral100: UIColor = UIColor(hex: 0xefefefff)
    static let neutral150: UIColor = UIColor(hex: 0xd8d8d8ff)
    static let neutral200: UIColor = UIColor(hex: 0xc4c4c4ff)
    static let neutral300: UIColor = UIColor(hex: 0xabababff)
    static let neutral400: UIColor = UIColor(hex: 0x8f8f8fff)
    static let neutral50: UIColor = UIColor(hex: 0xf8f8f8ff)
    static let neutral500: UIColor = UIColor(hex: 0x6a6a6aff)
    static let neutral600: UIColor = UIColor(hex: 0x565656ff)
    static let neutral700: UIColor = UIColor(hex: 0x464646ff)
    static let neutral800: UIColor = UIColor(hex: 0x323232ff)
    static let neutral900: UIColor = UIColor(hex: 0x1c1c1cff)
    static let purple100: UIColor = UIColor(hex: 0xecedffff)
    static let purple150: UIColor = UIColor(hex: 0xd4d7ffff)
    static let purple200: UIColor = UIColor(hex: 0xc1c5ffff)
    static let purple300: UIColor = UIColor(hex: 0xa1a3ffff)
    static let purple400: UIColor = UIColor(hex: 0x8482fcff)
    static let purple50: UIColor = UIColor(hex: 0xf7f8ffff)
    static let purple500: UIColor = UIColor(hex: 0x644af9ff)
    static let purple600: UIColor = UIColor(hex: 0x553bd8ff)
    static let purple700: UIColor = UIColor(hex: 0x4032a1ff)
    static let purple800: UIColor = UIColor(hex: 0x2e2576ff)
    static let purple900: UIColor = UIColor(hex: 0x1a114dff)
    static let red100: UIColor = UIColor(hex: 0xffe7f2ff)
    static let red150: UIColor = UIColor(hex: 0xffccdfff)
    static let red200: UIColor = UIColor(hex: 0xffb1cdff)
    static let red300: UIColor = UIColor(hex: 0xfe87a1ff)
    static let red400: UIColor = UIColor(hex: 0xfc526aff)
    static let red50: UIColor = UIColor(hex: 0xfff5faff)
    static let red500: UIColor = UIColor(hex: 0xd90d10ff)
    static let red600: UIColor = UIColor(hex: 0xb3093cff)
    static let red700: UIColor = UIColor(hex: 0x890d37ff)
    static let red800: UIColor = UIColor(hex: 0x68052bff)
    static let red900: UIColor = UIColor(hex: 0x3e021aff)
    static let slate100: UIColor = UIColor(hex: 0xebeef1ff)
    static let slate150: UIColor = UIColor(hex: 0xd5dbe1ff)
    static let slate200: UIColor = UIColor(hex: 0xc0c8d2ff)
    static let slate300: UIColor = UIColor(hex: 0xa3acbaff)
    static let slate400: UIColor = UIColor(hex: 0x87909fff)
    static let slate50: UIColor = UIColor(hex: 0xf6f8faff)
    static let slate500: UIColor = UIColor(hex: 0x687385ff)
    static let slate600: UIColor = UIColor(hex: 0x545969ff)
    static let slate700: UIColor = UIColor(hex: 0x414552ff)
    static let slate800: UIColor = UIColor(hex: 0x30313dff)
    static let slate900: UIColor = UIColor(hex: 0x1a1b25ff)
    static let violet100: UIColor = UIColor(hex: 0xfbe8feff)
    static let violet150: UIColor = UIColor(hex: 0xf7cffcff)
    static let violet200: UIColor = UIColor(hex: 0xeeb5f4ff)
    static let violet300: UIColor = UIColor(hex: 0xe68becff)
    static let violet400: UIColor = UIColor(hex: 0xd75fe7ff)
    static let violet50: UIColor = UIColor(hex: 0xfef4ffff)
    static let violet500: UIColor = UIColor(hex: 0xb716caff)
    static let violet600: UIColor = UIColor(hex: 0x9d00aeff)
    static let violet700: UIColor = UIColor(hex: 0x7c0089ff)
    static let violet800: UIColor = UIColor(hex: 0x5c0066ff)
    static let violet900: UIColor = UIColor(hex: 0x36003dff)
    static let yellow100: UIColor = UIColor(hex: 0xfcedb9ff)
    static let yellow150: UIColor = UIColor(hex: 0xfcd579ff)
    static let yellow200: UIColor = UIColor(hex: 0xf6bf57ff)
    static let yellow300: UIColor = UIColor(hex: 0xfa922bff)
    static let yellow400: UIColor = UIColor(hex: 0xf26d10ff)
    static let yellow50: UIColor = UIColor(hex: 0xfef9daff)
    static let yellow500: UIColor = UIColor(hex: 0xc84801ff)
    static let yellow600: UIColor = UIColor(hex: 0xa82c00ff)
    static let yellow700: UIColor = UIColor(hex: 0x842106ff)
    static let yellow800: UIColor = UIColor(hex: 0x5f1a05ff)
    static let yellow900: UIColor = UIColor(hex: 0x331302ff)
}

extension UIColor {
    /// The color represented as SwiftUI color.
    public var toColor: Color {
        Color(self)
    }
}
