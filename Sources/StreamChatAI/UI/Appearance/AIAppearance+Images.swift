//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

extension AIAppearance {
    /// The icons the AI components render.
    @MainActor
    public final class Images {
        public nonisolated init() { /* Public init. */ }

        // MARK: - Composer

        public var composerAddAttachment = Image(systemName: "plus")
        public var composerSend = Image(systemName: "arrow.up.circle.fill")
        public var composerStopGenerating = Image(systemName: "stop.circle")
        public var composerStartDictation = Image(systemName: "mic")
        public var composerStopDictation = Image(systemName: "stop.circle")
        public var composerRemove = Image(systemName: "xmark")

        // MARK: - Attachment Picker

        public var attachmentPickerCamera = Image(systemName: "camera")
        public var attachmentSelected = Image(systemName: "checkmark")
        public var attachmentFailed = Image(systemName: "exclamationmark.triangle")

        // MARK: - Message

        public var codeBlockCopy = Image(systemName: "clipboard")

        // MARK: - Message Actions

        public var messageCopy = Image(systemName: "doc.on.doc")
        /// Shown for a moment once a message is copied.
        public var messageCopied = Image(systemName: "checkmark")
        public var messageShare = Image(systemName: "square.and.arrow.up")
        public var messageRegenerate = Image(systemName: "arrow.clockwise")
        public var messageRatePositive = Image(systemName: "hand.thumbsup")
        public var messageRatedPositive = Image(systemName: "hand.thumbsup.fill")
        public var messageRateNegative = Image(systemName: "hand.thumbsdown")
        public var messageRatedNegative = Image(systemName: "hand.thumbsdown.fill")
        public var messageEdit = Image(systemName: "pencil")

        // MARK: - Message Attachments

        /// The icon of a file of a type without one of its own.
        public var attachmentFile = Image(systemName: "doc")
        public var attachmentPDF = Image(systemName: "doc.richtext")
        public var attachmentImage = Image(systemName: "photo")
        public var attachmentAudio = Image(systemName: "waveform")
        public var attachmentVideo = Image(systemName: "film")
        public var attachmentArchive = Image(systemName: "doc.zipper")

        // MARK: - Conversation

        /// The button that scrolls to the end of the conversation.
        public var conversationScrollToLatest = Image(systemName: "arrow.down")

        // MARK: - Reasoning

        public var reasoning = Image(systemName: "brain")
        public var reasoningDisclosure = Image(systemName: "chevron.right")

        // MARK: - Tool Call

        public var toolCallAwaitingApproval = Image(systemName: "hand.raised")
        public var toolCallAwaitingAuthorization = Image(systemName: "person.badge.key")
        public var toolCallAwaitingDevice = Image(systemName: "iphone")
        public var toolCallCompleted = Image(systemName: "checkmark")
        public var toolCallFailed = Image(systemName: "exclamationmark")
        public var toolCallCancelled = Image(systemName: "xmark")
        /// The placeholder for a step this version of the SDK can't show.
        public var unsupportedPart = Image(systemName: "sparkles")
    }
}
