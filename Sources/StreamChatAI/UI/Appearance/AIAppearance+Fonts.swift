//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCoreUI
import SwiftUI

extension AIAppearance {
    /// Fonts of the AI components, derived from the shared ``DesignSystemTokens``.
    ///
    /// They read the tokens lazily, so change the tokens before the first read.
    @MainActor
    public final class Fonts {
        private nonisolated(unsafe) let fonts: DesignSystemTokens.Fonts

        // MARK: - Composer

        /// The selected chat option above the text field.
        public lazy var composerChatOption: Font = fonts.headline
        public lazy var chatOptionTitle: Font = fonts.headline
        public lazy var chatOptionDescription: Font = fonts.subheadline
        public lazy var suggestion: Font = fonts.subheadline

        // MARK: - Message

        public lazy var codeBlockLanguage: Font = .system(.caption, design: .monospaced)
        public lazy var chartTitle: Font = fonts.headline
        /// The shares written on a pie chart.
        public lazy var chartAnnotation: Font = .caption2

        // MARK: - Message Parts

        /// Reasoning, tool calls and tool approvals, unless a view is given its own font.
        public lazy var messagePart: Font = fonts.subheadline
        /// The note under the open reasoning.
        public lazy var reasoningFootnote: Font = .caption2
        /// A tool call's outcome and duration.
        public lazy var toolCallDetail: Font = fonts.caption1
        /// The agent's reason and what allowing a tool call shares.
        public lazy var toolApprovalMessage: Font = fonts.footnote
        /// The note when an answer could not be sent.
        public lazy var toolApprovalFailure: Font = fonts.caption1

        public nonisolated init(tokens: DesignSystemTokens = DesignSystemTokens()) {
            fonts = tokens.fonts
        }
    }
}
