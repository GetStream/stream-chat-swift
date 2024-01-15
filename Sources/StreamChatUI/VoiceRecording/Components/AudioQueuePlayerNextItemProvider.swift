//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// An object responsible for providing the next VoiceRecording to play.
open class AudioQueuePlayerNextItemProvider {
    /// Describes the lookUp scope in which the Provider will look into for the next available VoiceRecording.
    public struct LookUpScope: RawRepresentable, Equatable {
        public var rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }

        /// The provider will look for the next VoiceRecording in the attachments of the message containing
        /// the currently playing URL.
        public static let sameMessage = LookUpScope(rawValue: "same-message")

        /// The provider will look for the next VoiceRecording in the attachments of the of the message containing
        /// the currently playing URL and if not found will apply the same logic in all subsequent messages
        /// that have the same author.
        public static let subsequentMessagesFromUser = LookUpScope(rawValue: "subsequent-messages-from-user")
    }

    public required init() {}

    /// Finds the URL of the the next VoiceRecording to play. It's looking first in the currentMessage
    /// to find the next attachment available and if non found it will find the message after the current one
    /// and return its first VoiceRecording attachment.
    /// - Parameters:
    ///   - messages: The messages to look into.
    ///   - currentVoiceRecordingURL: The URL of the currently playing attachment.
    ///   - lookUpScope: The scope in which we should look for the next available VoiceRecording.
    /// - Returns: Returns the next available VoiceRecording URL to play.
    open func findNextItem(
        in messages: [ChatMessage],
        currentVoiceRecordingURL: URL?,
        lookUpScope: LookUpScope
    ) -> URL? {
        guard
            !messages.isEmpty,
            let currentVoiceRecordingURL = currentVoiceRecordingURL
        else {
            return nil
        }

        let currentVoiceRecordingMessage = findVoiceRecordingMessage(
            in: messages,
            containingAttachmentWithURL: currentVoiceRecordingURL
        )

        guard
            let currentVoiceRecordingMessage = currentVoiceRecordingMessage,
            !currentVoiceRecordingMessage.isSentByCurrentUser
        else {
            return nil
        }

        let nextVoiceRecordingInCurrentMessage = findVoiceRecordingAttachmentAfter(
            attachmentWithURL: currentVoiceRecordingURL,
            in: currentVoiceRecordingMessage
        )

        switch lookUpScope {
        case .sameMessage:
            return nextVoiceRecordingInCurrentMessage?.voiceRecordingURL

        case .subsequentMessagesFromUser:
            if let nextVoiceRecordingInCurrentMessage = nextVoiceRecordingInCurrentMessage {
                return nextVoiceRecordingInCurrentMessage.voiceRecordingURL

            } else if let nextMessage = findMessageBefore(
                message: currentVoiceRecordingMessage,
                in: messages
            ), nextMessage.author.id == currentVoiceRecordingMessage.author.id {
                return nextMessage.voiceRecordingAttachments.first?.voiceRecordingURL

            } else {
                return nil
            }

        default:
            return nil
        }
    }

    // MARK: - Helpers

    private func voiceRecordingMessages(
        in messages: [ChatMessage],
        includeMessagesSentByCurrentUser: Bool
    ) -> [ChatMessage] {
        messages.filter { message in
            guard
                !message.isSentByCurrentUser || includeMessagesSentByCurrentUser,
                !message.voiceRecordingAttachments.isEmpty
            else {
                return false
            }
            return true
        }
    }

    private func findVoiceRecordingMessage(
        in messages: [ChatMessage],
        containingAttachmentWithURL url: URL
    ) -> ChatMessage? {
        messages.first { message in
            message.voiceRecordingAttachments.first { attachment in
                attachment.voiceRecordingURL == url
            } != nil
        }
    }

    private func findMessageBefore(
        message: ChatMessage,
        in messages: [ChatMessage]
    ) -> ChatMessage? {
        guard
            let messageIndex = messages.lastIndex(of: message)
        else {
            return nil
        }

        let indexBefore = messages.index(before: messageIndex)

        guard messages.indices.contains(indexBefore) else {
            return nil
        }

        return messages[indexBefore]
    }

    private func findVoiceRecordingAttachmentAfter(
        attachmentWithURL url: URL,
        in message: ChatMessage
    ) -> ChatMessageVoiceRecordingAttachment? {
        let voiceRecordingAttachments = message.voiceRecordingAttachments
        guard
            let attachment = voiceRecordingAttachments.first(where: { $0.voiceRecordingURL == url }),
            let attachmentIndex = voiceRecordingAttachments.firstIndex(of: attachment)
        else {
            return nil
        }

        let indexAfter = voiceRecordingAttachments.index(after: attachmentIndex)

        guard let voiceRecordingAttachment = voiceRecordingAttachments[safe: indexAfter] else {
            return nil
        }

        return voiceRecordingAttachment
    }
}
