//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import UIKit

extension AIAppearance {
    /// Colors of the AI components, derived from the shared ``DesignSystemTokens``.
    ///
    /// They read the tokens lazily, so change the tokens before the first read.
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

        // MARK: - Message

        public lazy var codeBlockBackground: UIColor = colors.backgroundCoreSurfaceSubtle

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

        public init(tokens: DesignSystemTokens = DesignSystemTokens()) {
            colors = tokens.colors
        }
    }
}
