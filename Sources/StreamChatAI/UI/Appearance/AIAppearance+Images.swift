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

        // MARK: - Reasoning

        public var reasoning = Image(systemName: "brain")
        public var reasoningDisclosure = Image(systemName: "chevron.right")

        // MARK: - Tool Call

        public var toolCallAwaitingApproval = Image(systemName: "hand.raised")
        public var toolCallAwaitingDevice = Image(systemName: "iphone")
        public var toolCallCompleted = Image(systemName: "checkmark")
        public var toolCallFailed = Image(systemName: "exclamationmark")
        public var toolCallCancelled = Image(systemName: "xmark")
        /// The placeholder for a step this version of the SDK can't show.
        public var unsupportedPart = Image(systemName: "sparkles")
    }
}
