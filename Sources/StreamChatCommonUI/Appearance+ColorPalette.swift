//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit

public extension Appearance {
    @MainActor final class ColorPalette {
        // MARK: - Accent

        /// The main brand color. Used for interactive elements, buttons, links, and primary actions.
        /// Override this to apply your brand color across the SDK.
        public lazy var accentPrimary: UIColor = UIColor(light: brand500, dark: brand400)
        /// Indicates a positive or completed state. Used for confirmations and success feedback.
        public lazy var accentSuccess: UIColor = UIColor(light: .green400, dark: .green300)
        /// Indicates a failure or destructive state. Used for failed messages, validation errors, and deletions.
        public lazy var accentError: UIColor = UIColor(light: .red500, dark: .red400)
        /// A mid-tone gray for de-emphasized UI elements.
        public lazy var accentNeutral: UIColor = chrome500

        // MARK: - Background

        /// The outermost application background. Sits behind all surfaces.
        public lazy var backgroundCoreApp: UIColor = chrome0
        /// The base layer. Used as the reference point for the elevation scale.
        public lazy var backgroundCoreElevation0: UIColor = chrome0
        /// Slightly raised surfaces. Used for content containers like the message list and channel list.
        public lazy var backgroundCoreElevation1: UIColor = UIColor(light: chrome0, dark: chrome50)
        /// Floating and modal surfaces. Used for popovers, dropdowns, and dialogs.
        public lazy var backgroundCoreElevation2: UIColor = UIColor(light: chrome0, dark: chrome100)
        /// Used for badge counts that float above other UI elements.
        public lazy var backgroundCoreElevation3: UIColor = UIColor(light: chrome0, dark: chrome200)
        /// Background for sectioned content areas. Used for grouped containers and distinct content regions.
        public lazy var backgroundCoreSurfaceDefault: UIColor = chrome100
        /// A slightly receded background. Used for secondary containers or to create soft visual separation.
        public lazy var backgroundCoreSurfaceSubtle: UIColor = chrome50
        /// Background for contained, card-style elements. Matches the surface in light mode but lifts slightly in dark mode.
        public lazy var backgroundCoreSurfaceCard: UIColor = UIColor(light: chrome50, dark: chrome100)
        /// A more prominent background. Used for elements that need to stand out from the main surface.
        public lazy var backgroundCoreSurfaceStrong: UIColor = chrome150
        /// The opposite of the primary surface. Used for tooltips, snackbars, and high-contrast floating elements.
        public lazy var backgroundCoreInverse: UIColor = chrome1000
        /// Background for elements placed on an accent-colored surface. Ensures legibility against brand colors.
        public lazy var backgroundCoreOnAccent: UIColor = UIColor(light: chrome0, dark: chrome1000)
        /// A tint for drawing attention to content. Used for highlights and pinned messages.
        public lazy var backgroundCoreHighlight: UIColor = UIColor(light: .yellow50, dark: .yellow800)
        /// A light semi-transparent layer. Used to lighten surfaces and for hover states on dark backgrounds.
        public lazy var backgroundCoreOverlayLight: UIColor = UIColor(light: UIColor(hex: 0xffffffbf), dark: UIColor(hex: 0x000000bf))
        /// A dark semi-transparent layer. Used for image overlays.
        public lazy var backgroundCoreOverlayDark: UIColor = UIColor(light: UIColor(hex: 0x1a1b2540), dark: UIColor(hex: 0x00000080))
        /// A heavy semi-transparent layer. Used behind sheets, drawers, and modals to separate them from content.
        public lazy var backgroundCoreScrim: UIColor = UIColor(light: UIColor(hex: 0x1a1b2580), dark: UIColor(hex: 0x000000bf))
        /// A slightly stronger overlay applied during an active press or tap. Provides tactile feedback on interactive elements.
        public lazy var backgroundUtilityPressed: UIColor = UIColor(light: UIColor(hex: 0x1a1b2526), dark: UIColor(hex: 0xffffff33))
        /// Indicates an active or selected state. Used for selected messages, active list items, and toggled controls.
        public lazy var backgroundUtilitySelected: UIColor = UIColor(light: UIColor(hex: 0x1a1b2533), dark: UIColor(hex: 0xffffff40))
        /// Background for non-interactive elements. Flattens the element visually to signal unavailability.
        public lazy var backgroundUtilityDisabled: UIColor = chrome100

        // MARK: - Text

        /// Main body text. Used for message content, titles, and any text that carries primary meaning.
        public lazy var textPrimary: UIColor = chrome900
        /// Supporting metadata text. Used for timestamps, subtitles, and secondary labels.
        public lazy var textSecondary: UIColor = chrome700
        /// De-emphasized text. Used for hints, placeholders, and lowest-priority supporting information.
        public lazy var textTertiary: UIColor = chrome500
        /// Text on inverse-colored surfaces. Flips between light and dark to maintain legibility when the background inverts.
        public lazy var textOnInverse: UIColor = chrome0
        /// Text on accent-colored surfaces. Stays white in both light and dark mode since the accent background does not invert.
        public lazy var textOnAccent: UIColor = UIColor(light: chrome0, dark: chrome1000)
        /// Text for non-interactive or unavailable states. Communicates that an element cannot be interacted with.
        public lazy var textDisabled: UIColor = chrome300
        /// Hyperlinks and inline actions. Uses the brand color to signal interactivity within text content.
        public lazy var textLink: UIColor = UIColor(light: brand500, dark: brand600)

        // MARK: - Border

        /// Standard border for surfaces and containers. Used for input fields, cards, and dividers on neutral backgrounds.
        public lazy var borderCoreDefault: UIColor = UIColor(light: chrome150, dark: chrome200)
        /// A lighter border for minimal separation. Used where a full-strength border would feel too heavy.
        public lazy var borderCoreSubtle: UIColor = chrome100
        /// An emphatic border for elements that need clear definition. Used for focused containers and prominent dividers.
        public lazy var borderCoreStrong: UIColor = chrome300
        /// Border on inverse-colored surfaces. Stays legible when the background flips between light and dark mode.
        public lazy var borderCoreInverse: UIColor = chrome0
        /// Border on inverse-colored surfaces used as a separator element.
        public lazy var borderCoreOnInverse: UIColor = chrome0
        /// Border on accent-colored surfaces. Stays white in both light and dark mode since the accent background does not invert.
        public lazy var borderCoreOnAccent: UIColor = UIColor(light: chrome0, dark: chrome1000)
        /// A very light transparent border. Used as a frame treatment on images and media attachments.
        public lazy var borderCoreOpacitySubtle: UIColor = UIColor(light: UIColor(hex: 0x1a1b251a), dark: UIColor(hex: 0xffffff33))
        /// A stronger transparent border for elements on colored or dark backgrounds. Used for waveform bars and similar treatments.
        public lazy var borderCoreOpacityStrong: UIColor = UIColor(light: UIColor(hex: 0x1a1b2540), dark: UIColor(hex: 0xffffff40))
        /// Border for non-interactive elements. Matches the disabled surface to visually flatten the element.
        public lazy var borderUtilityDisabled: UIColor = chrome100
        /// Border for disabled elements on elevated surfaces. Stays visually distinct from the surface without drawing attention.
        public lazy var borderUtilityDisabledOnSurface: UIColor = chrome150

        // MARK: - Avatar

        /// Default avatar background color.
        public lazy var avatarBackgroundDefault: UIColor = avatarPaletteBackground1
        /// First palette option for avatar backgrounds.
        public lazy var avatarPaletteBackground1: UIColor = UIColor(light: .blue150, dark: .blue600)
        /// Text color paired with the first avatar palette background.
        public lazy var avatarPaletteText1: UIColor = UIColor(light: .blue900, dark: .blue100)
        /// Default text color for avatar initials.
        public lazy var avatarTextDefault: UIColor = avatarPaletteText1

        // MARK: - Badge

        /// Background for the default badge variant.
        public lazy var badgeBackgroundDefault: UIColor = backgroundCoreElevation3
        /// Background for error badges indicating failures or critical counts.
        public lazy var badgeBackgroundError: UIColor = accentError
        /// Background for badges on light surfaces requiring high contrast.
        public lazy var badgeBackgroundInverse: UIColor = chrome1000
        /// Background for neutral, informational badges.
        public lazy var badgeBackgroundNeutral: UIColor = accentNeutral
        /// Background for badges overlaid on media or images.
        public lazy var badgeBackgroundOverlay: UIColor = UIColor(hex: 0x000000bf)
        /// Background for primary-styled badges.
        public lazy var badgeBackgroundPrimary: UIColor = accentPrimary
        /// Border color for badges.
        public lazy var badgeBorder: UIColor = borderCoreOnInverse
        /// Text color for badges on default backgrounds.
        public lazy var badgeText: UIColor = textPrimary
        /// Text color for badges on accent-colored backgrounds.
        public lazy var badgeTextOnAccent: UIColor = textOnAccent
        /// Text color for badges on inverse backgrounds.
        public lazy var badgeTextOnInverse: UIColor = textOnInverse

        // MARK: - Button

        /// Background for primary action buttons.
        public lazy var buttonPrimaryBackground: UIColor = accentPrimary
        /// Background for primary buttons with Liquid Glass material.
        public lazy var buttonPrimaryBackgroundLiquidGlass: UIColor = .baseTransparent0
        /// Border for primary action buttons.
        public lazy var buttonPrimaryBorder: UIColor = brand200
        /// Text color for outlined primary buttons.
        public lazy var buttonPrimaryText: UIColor = accentPrimary
        /// Text color for filled primary buttons.
        public lazy var buttonPrimaryTextOnAccent: UIColor = textOnAccent
        /// Background for secondary action buttons.
        public lazy var buttonSecondaryBackground: UIColor = backgroundCoreSurfaceDefault
        /// Background for secondary buttons with Liquid Glass material.
        public lazy var buttonSecondaryBackgroundLiquidGlass: UIColor = backgroundCoreElevation0
        /// Border for secondary action buttons.
        public lazy var buttonSecondaryBorder: UIColor = borderCoreDefault
        /// Text color for secondary buttons.
        public lazy var buttonSecondaryText: UIColor = textPrimary
        /// Text color for filled secondary buttons.
        public lazy var buttonSecondaryTextOnAccent: UIColor = textPrimary
        /// Background for destructive action buttons.
        public lazy var buttonDestructiveBackground: UIColor = accentError
        /// Background for destructive buttons with Liquid Glass material.
        public lazy var buttonDestructiveBackgroundLiquidGlass: UIColor = backgroundCoreElevation0
        /// Border for destructive action buttons.
        public lazy var buttonDestructiveBorder: UIColor = accentError
        /// Text color for outlined destructive buttons.
        public lazy var buttonDestructiveText: UIColor = accentError
        /// Text color for filled destructive buttons.
        public lazy var buttonDestructiveTextOnAccent: UIColor = textOnAccent

        // MARK: - Chat

        /// Bubble background for incoming messages.
        public lazy var chatBackgroundIncoming: UIColor = backgroundCoreSurfaceDefault
        /// Bubble background for outgoing messages.
        public lazy var chatBackgroundOutgoing: UIColor = brand100
        /// Background for attachment previews in incoming messages.
        public lazy var chatBackgroundAttachmentIncoming: UIColor = backgroundCoreSurfaceStrong
        /// Background for attachment previews in outgoing messages.
        public lazy var chatBackgroundAttachmentOutgoing: UIColor = brand150
        /// Border for incoming message bubbles.
        public lazy var chatBorderIncoming: UIColor = borderCoreSubtle
        /// Border for outgoing message bubbles.
        public lazy var chatBorderOutgoing: UIColor = brand100
        /// Border for elements inside incoming message bubbles.
        public lazy var chatBorderOnChatIncoming: UIColor = borderCoreStrong
        /// Border for elements inside outgoing message bubbles.
        public lazy var chatBorderOnChatOutgoing: UIColor = brand300
        /// Text color for incoming messages.
        public lazy var chatTextIncoming: UIColor = textPrimary
        /// Text color for outgoing messages.
        public lazy var chatTextOutgoing: UIColor = brand900
        /// Link text color within chat messages.
        public lazy var chatTextLink: UIColor = textLink
        /// Text color for system messages.
        public lazy var chatTextSystem: UIColor = textSecondary
        /// Text color for message timestamps.
        public lazy var chatTextTimestamp: UIColor = textTertiary
        /// Text color for the typing indicator.
        public lazy var chatTextTypingIndicator: UIColor = chatTextIncoming
        /// Text color for usernames in chat.
        public lazy var chatTextUsername: UIColor = textSecondary
        /// Reply thread indicator color for incoming messages.
        public lazy var chatReplyIndicatorIncoming: UIColor = chrome400
        /// Reply thread indicator color for outgoing messages.
        public lazy var chatReplyIndicatorOutgoing: UIColor = brand400
        /// Poll progress bar fill color in incoming messages.
        public lazy var chatPollProgressFillIncoming: UIColor = controlProgressBarFill
        /// Poll progress bar fill color in outgoing messages.
        public lazy var chatPollProgressFillOutgoing: UIColor = accentPrimary
        /// Poll progress bar track color in incoming messages.
        public lazy var chatPollProgressTrackIncoming: UIColor = controlProgressBarTrack
        /// Poll progress bar track color in outgoing messages.
        public lazy var chatPollProgressTrackOutgoing: UIColor = brand200

        // MARK: - Control

        /// Border for checkbox controls.
        public lazy var controlCheckboxBorder: UIColor = borderCoreDefault
        /// Text color for chip controls.
        public lazy var controlChipText: UIColor = textPrimary
        /// Background for the active playback scrubber thumb.
        public lazy var controlPlaybackThumbBackgroundActive: UIColor = accentPrimary
        /// Background for the default playback scrubber thumb.
        public lazy var controlPlaybackThumbBackgroundDefault: UIColor = backgroundCoreOnAccent
        /// Border for the active playback scrubber thumb.
        public lazy var controlPlaybackThumbBorderActive: UIColor = borderCoreOnAccent
        /// Border for the default playback scrubber thumb.
        public lazy var controlPlaybackThumbBorderDefault: UIColor = borderCoreOpacityStrong
        /// Background for the play button overlay.
        public lazy var controlPlayButtonBackground: UIColor = UIColor(hex: 0x000000bf)
        /// Icon color for the play button overlay.
        public lazy var controlPlayButtonIcon: UIColor = textOnAccent
        /// Fill color for progress bars.
        public lazy var controlProgressBarFill: UIColor = accentNeutral
        /// Track color for progress bars.
        public lazy var controlProgressBarTrack: UIColor = backgroundCoreSurfaceStrong
        /// Background for selected radio buttons and checkmarks.
        public lazy var controlRadioCheckBackgroundSelected: UIColor = accentPrimary
        /// Border for radio buttons and checkmarks.
        public lazy var controlRadioCheckBorder: UIColor = borderCoreDefault
        /// Icon color for the check indicator in radio buttons and checkmarks.
        public lazy var controlRadioCheckIcon: UIColor = textOnAccent
        /// Background for the remove/delete control.
        public lazy var controlRemoveControlBackground: UIColor = backgroundCoreInverse
        /// Border for the remove/delete control.
        public lazy var controlRemoveControlBorder: UIColor = borderCoreOnInverse
        /// Icon color for the remove/delete control.
        public lazy var controlRemoveControlIcon: UIColor = textOnInverse

        // MARK: - Input

        /// Send button icon color when the input is empty or disabled.
        public lazy var inputSendIconDisabled: UIColor = textDisabled
        /// Default text color for input fields.
        public lazy var inputTextDefault: UIColor = textPrimary
        /// Icon color within input fields.
        public lazy var inputTextIcon: UIColor = textTertiary
        /// Placeholder text color for input fields.
        public lazy var inputTextPlaceholder: UIColor = textTertiary

        // MARK: - Presence

        /// Background for the offline presence indicator.
        public lazy var presenceBackgroundOffline: UIColor = accentNeutral
        /// Background for the online presence indicator.
        public lazy var presenceBackgroundOnline: UIColor = accentSuccess
        /// Border for presence indicator dots.
        public lazy var presenceBorder: UIColor = borderCoreInverse

        // MARK: - Reaction

        /// Background for reaction pills.
        public lazy var reactionBackground: UIColor = backgroundCoreElevation3
        /// Border for reaction pills.
        public lazy var reactionBorder: UIColor = borderCoreDefault
        /// Text color for reaction counts.
        public lazy var reactionText: UIColor = textPrimary

        // MARK: - Navigation (SwiftUI SDK only)

        /// Title text color in the navigation bar.
        public lazy var navigationBarTitle: UIColor = textPrimary {
            didSet {
                StreamConcurrency.onMain { [navigationBarTitle] in
                    let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: navigationBarTitle]
                    UINavigationBar.appearance().titleTextAttributes = attributes
                    UINavigationBar.appearance().largeTitleTextAttributes = attributes
                }
            }
        }

        /// Subtitle text color in the navigation bar.
        public lazy var navigationBarSubtitle: UIColor = textTertiary
        /// Background color for the navigation bar. Defaults to system appearance when `nil`.
        public var navigationBarBackground: UIColor?
        /// Tint color for navigation bar buttons and icons.
        public lazy var navigationBarTintColor: UIColor = accentPrimary
        /// Color for navigation bar glyph elements.
        public lazy var navigationBarGlyph: UIColor = .baseWhite

        // MARK: - Utilities

        /// Returns a highlighted variant of the given color. Used for tap/press states in UIKit views.
        public var highlightedColorForColor: @Sendable (UIColor) -> UIColor = { $0.withAlphaComponent(0.5) }

        // MARK: - Internal

        var brand100: UIColor { UIColor(light: .blue100, dark: .blue800) }
        var brand150: UIColor { UIColor(light: .blue150, dark: .blue700) }
        var brand200: UIColor { UIColor(light: .blue200, dark: .blue600) }
        var brand300: UIColor { UIColor(light: .blue300, dark: .blue500) }
        var brand400: UIColor { .blue400 }
        var brand50: UIColor { UIColor(light: .blue50, dark: .blue900) }
        var brand500: UIColor { UIColor(light: .blue500, dark: .blue300) }
        var brand600: UIColor { UIColor(light: .blue600, dark: .blue200) }
        var brand700: UIColor { UIColor(light: .blue700, dark: .blue150) }
        var brand800: UIColor { UIColor(light: .blue800, dark: .blue100) }
        var brand900: UIColor { UIColor(light: .blue900, dark: .blue50) }
        var chrome0: UIColor { UIColor(light: .baseWhite, dark: .baseBlack) }
        var chrome100: UIColor { UIColor(light: .slate100, dark: .neutral800) }
        var chrome1000: UIColor { UIColor(light: .baseBlack, dark: .baseWhite) }
        var chrome150: UIColor { UIColor(light: .slate150, dark: .neutral700) }
        var chrome200: UIColor { UIColor(light: .slate200, dark: .neutral600) }
        var chrome300: UIColor { UIColor(light: .slate300, dark: .neutral500) }
        var chrome400: UIColor { UIColor(light: .slate400, dark: .neutral400) }
        var chrome50: UIColor { UIColor(light: .slate50, dark: .neutral900) }
        var chrome500: UIColor { UIColor(light: .slate500, dark: .neutral300) }
        var chrome600: UIColor { UIColor(light: .slate600, dark: .neutral200) }
        var chrome700: UIColor { UIColor(light: .slate700, dark: .neutral150) }
        var chrome800: UIColor { UIColor(light: .slate800, dark: .neutral100) }
        var chrome900: UIColor { UIColor(light: .slate900, dark: .neutral50) }

        public init() {
            // Public init.
        }
    }
}

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
