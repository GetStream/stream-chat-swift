//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
extension AIAppearance {
    /// Fonts of the AI components, derived from the shared ``DesignSystemTokens``.
    ///
    /// They read the tokens lazily, so change the tokens before the first read.
    @MainActor
    public final class Fonts {
        private let fonts: DesignSystemTokens.Fonts
        private let layout: DesignSystemTokens.Layout

        // MARK: - Composer

        /// The selected chat option above the text field.
        public lazy var composerChatOption: Font = fonts.headline
        public lazy var chatOptionTitle: Font = fonts.headline
        public lazy var chatOptionDescription: Font = fonts.subheadline
        public lazy var suggestion: Font = fonts.subheadline

        // MARK: - Attachment Picker

        /// The icon of a photo's tile that couldn't load.
        public lazy var attachmentPickerTileFailureIcon: Font = fonts.title2.weight(.semibold)
        /// The icon of a tile's badge, such as its check mark or its remove button.
        public lazy var attachmentBadgeIcon: Font = .system(size: layout.iconSizeXs, weight: .bold)

        // MARK: - Message

        public lazy var codeBlockLanguage: Font = fonts.caption1.monospaced()
        public lazy var chartTitle: Font = fonts.headline
        /// The shares written on a pie chart.
        public lazy var chartAnnotation: Font = fonts.caption1

        // MARK: - Message Parts

        /// Reasoning, tool calls and tool approvals, unless a view is given its own font.
        public lazy var messagePart: Font = fonts.subheadline
        /// The note under the open reasoning.
        public lazy var reasoningFootnote: Font = fonts.caption1
        /// The chevron that opens and closes the reasoning.
        public lazy var reasoningDisclosure: Font = fonts.caption1.weight(.semibold)
        /// A tool call's outcome and duration.
        public lazy var toolCallDetail: Font = fonts.caption1
        /// The agent's reason and what allowing a tool call shares.
        public lazy var toolApprovalMessage: Font = fonts.footnote
        /// The note when an answer could not be sent.
        public lazy var toolApprovalFailure: Font = fonts.caption1

        // MARK: - Conversation

        /// A message the person sent.
        public lazy var userMessage: Font = fonts.body
        /// The icons of the buttons under a reply, such as copy and regenerate.
        public lazy var messageAction: Font = fonts.subheadline
        /// The arrow of the button that scrolls to the end of the conversation.
        public lazy var conversationScrollButton: Font = fonts.bodyBold

        // MARK: - Message Attachments

        /// The icon of a file's type, such as PDF.
        public lazy var attachmentIcon: Font = fonts.subheadline
        public lazy var attachmentName: Font = fonts.subheadlineBold
        /// A file's type and size.
        public lazy var attachmentDetails: Font = fonts.caption1

        public nonisolated init(tokens: DesignSystemTokens = DesignSystemTokens()) {
            fonts = tokens.fonts
            layout = tokens.layout
        }
    }
}
