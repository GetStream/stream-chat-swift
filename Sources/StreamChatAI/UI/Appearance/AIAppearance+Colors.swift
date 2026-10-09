//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import UIKit

extension AIAppearance {
    /// Colors of the AI components, derived from the shared ``DesignSystemTokens``.
    ///
    /// They read the tokens lazily, so change the tokens before the first read.
    @MainActor
    public final class Colors {
        private let colors: DesignSystemTokens.Colors

        // MARK: - Composer

        public lazy var composerBackground: UIColor = colors.backgroundCoreSurfaceDefault
        public lazy var composerText: UIColor = colors.inputTextDefault
        /// The dictation and stop-generating buttons.
        public lazy var composerIcon: UIColor = colors.inputTextIcon
        public lazy var composerAttachmentButtonBackground: UIColor = colors.backgroundCoreSurfaceDefault
        public lazy var composerAttachmentButtonIcon: UIColor = colors.inputTextIcon
        /// The chip of the selected chat option.
        public lazy var composerChatOptionBackground: UIColor = colors.backgroundCoreElevation1
        public lazy var composerChatOptionText: UIColor = colors.accentPrimary

        // MARK: - Attachment Picker

        public lazy var attachmentPickerButtonBackground: UIColor = colors.backgroundCoreSurfaceDefault
        public lazy var attachmentPickerTileBackground: UIColor = colors.backgroundCoreSurfaceSubtle
        public lazy var attachmentPickerTileIcon: UIColor = colors.textPrimary
        public lazy var attachmentPickerTileFailureIcon: UIColor = colors.textSecondary
        public lazy var attachmentPickerOptionTitle: UIColor = colors.textPrimary
        public lazy var attachmentPickerOptionDescription: UIColor = colors.textSecondary
        public lazy var attachmentBadgeBackground: UIColor = colors.badgeBackgroundOverlay
        public lazy var attachmentBadgeSelectedBackground: UIColor = colors.accentPrimary
        /// The badge's icon, its ring, and the outline of an unselected badge.
        public lazy var attachmentBadgeForeground: UIColor = colors.textOnAccent

        // MARK: - Suggestions

        public lazy var suggestionBackground: UIColor = colors.backgroundCoreSurfaceDefault
        public lazy var suggestionText: UIColor = colors.textPrimary

        // MARK: - Code

        public lazy var codeBlockBackground: UIColor = colors.backgroundCoreSurfaceSubtle
        /// The bar above the code, with its language and the copy button.
        public lazy var codeBlockHeaderBackground: UIColor = colors.backgroundCoreSurfaceDefault
        public lazy var codeBlockHeaderText: UIColor = colors.textPrimary
        /// Code that isn't highlighted.
        public lazy var codeText: UIColor = colors.textPrimary
        public lazy var codeKeyword: UIColor = .code(light: 0x294277, dark: 0xfc5fa3)
        public lazy var codeString: UIColor = .code(light: 0xdf0700, dark: 0xfc6a5d)
        public lazy var codeType: UIColor = .code(light: 0xb44500, dark: 0x5dd8ff)
        public lazy var codeCall: UIColor = .code(light: 0x476a97, dark: 0x67b7a4)
        public lazy var codeNumber: UIColor = .code(light: 0x294277, dark: 0xd0bf69)
        public lazy var codeComment: UIColor = .code(light: 0xc3741c, dark: 0x7f8c98)
        public lazy var codeProperty: UIColor = .code(light: 0x476a97, dark: 0x67b7a4)
        public lazy var codeDotAccess: UIColor = .code(light: 0x476a97, dark: 0xa167e6)
        public lazy var codePreprocessing: UIColor = .code(light: 0x646485, dark: 0xfd8f3f)

        // MARK: - Reasoning

        /// The header, such as "Thinking…" and "Thought for 12s", and its icons.
        public lazy var reasoningTitle: UIColor = colors.textSecondary
        public lazy var reasoningText: UIColor = colors.textSecondary
        /// The note under the open reasoning.
        public lazy var reasoningFootnote: UIColor = colors.textTertiary
        /// The highlight that sweeps across the header while the model thinks.
        public lazy var reasoningShimmer: UIColor = colors.textPrimary
        /// The rule along the reasoning's leading edge.
        public lazy var reasoningRule: UIColor = colors.borderCoreDefault

        // MARK: - Tool Call

        /// What a call is doing, such as "Checking your location".
        public lazy var toolCallTitle: UIColor = colors.textPrimary
        /// A call's outcome, its duration, and the placeholder for unknown steps.
        public lazy var toolCallDetail: UIColor = colors.textSecondary
        /// A call in progress, including one waiting for a device.
        public lazy var toolCallAccent: UIColor = colors.accentPrimary
        public lazy var toolCallSuccess: UIColor = colors.accentSuccess
        public lazy var toolCallFailure: UIColor = colors.accentError

        // MARK: - Tool Approval

        /// The question, such as "Share your location?".
        public lazy var toolApprovalTitle: UIColor = colors.textPrimary
        /// The agent's reason and what allowing the call shares.
        public lazy var toolApprovalMessage: UIColor = colors.textSecondary
        public lazy var toolApprovalBackground: UIColor = colors.backgroundCoreSurfaceCard
        public lazy var toolApprovalBorder: UIColor = colors.borderCoreDefault
        /// The tint of the buttons that allow or decline the call.
        public lazy var toolApprovalAccent: UIColor = colors.accentPrimary
        /// The note when an answer could not be sent.
        public lazy var toolApprovalFailure: UIColor = colors.accentError

        // MARK: - Sidebar

        public lazy var sidebarBackground: UIColor = colors.backgroundCoreApp
        /// The dimming over the content while the sidebar is open.
        public lazy var sidebarScrim: UIColor = colors.backgroundCoreOverlayDark

        public nonisolated init(tokens: DesignSystemTokens = DesignSystemTokens()) {
            colors = tokens.colors
        }
    }
}

private extension UIColor {
    // Syntax colors have no design token, so they keep a light and a dark variant here.
    static func code(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xff) / 255,
                green: CGFloat((hex >> 8) & 0xff) / 255,
                blue: CGFloat(hex & 0xff) / 255,
                alpha: 1
            )
        }
    }
}
