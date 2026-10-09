//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension ChatChannelController {
    /// Schedules a new message to be sent to the channel at a later date.
    ///
    /// The message is not added to the channel until it is sent. Local attachments are uploaded when scheduling.
    ///
    /// - Parameters:
    ///   - messageId: The id of the scheduled message. Scheduling twice with the same id returns the existing scheduled message.
    ///   - text: Text of the message.
    ///   - attachments: An array of the attachments for the message.
    ///   - mentionedUserIds: An array of the users mentioned in the message.
    ///   - quotedMessageId: An id of the message the new message quotes.
    ///   - extraData: Additional extra data of the message object.
    ///   - scheduledAt: When to send the message. At least 1 minute and at most 120 days from now.
    ///   - completion: Called when the message is scheduled, with the scheduled message or an error.
    func scheduleMessage(
        messageId: MessageId? = nil,
        text: String,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        quotedMessageId: MessageId? = nil,
        extraData: [String: RawJSON] = [:],
        scheduledAt: Date,
        completion: (@MainActor (Result<ScheduledMessage, Error>) -> Void)? = nil
    ) {
        guard let cid else {
            callback { completion?(.failure(ClientError.ChannelNotCreatedYet())) }
            return
        }
        let content = ScheduledMessageContent(
            text: text,
            attachments: attachments,
            mentionedUserIds: mentionedUserIds,
            quotedMessageId: quotedMessageId,
            parentId: nil,
            showReplyInChannel: false,
            extraData: extraData
        )
        client.scheduledMessagesRepository.schedule(
            id: messageId ?? .newUniqueId,
            cid: cid,
            content: content,
            scheduledAt: scheduledAt
        ) { result in
            self.callback { completion?(result) }
        }
    }

    /// Updates the content of a scheduled message, and optionally when it is sent.
    ///
    /// A failed scheduled message is scheduled again when `scheduledAt` is provided.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - text: The new text of the message.
    ///   - attachments: The new attachments of the message.
    ///   - mentionedUserIds: The new mentioned users of the message.
    ///   - quotedMessageId: The new quoted message of the message.
    ///   - extraData: The new extra data of the message.
    ///   - scheduledAt: When to send the message. `nil` keeps the current date.
    ///   - completion: Called when the message is updated, with the scheduled message or an error.
    func updateScheduledMessage(
        id: String,
        text: String,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        quotedMessageId: MessageId? = nil,
        extraData: [String: RawJSON] = [:],
        scheduledAt: Date? = nil,
        completion: (@MainActor (Result<ScheduledMessage, Error>) -> Void)? = nil
    ) {
        let repository = client.scheduledMessagesRepository
        let existing = repository.scheduledMessage(id: id)
        let content = ScheduledMessageContent(
            text: text,
            attachments: attachments,
            mentionedUserIds: mentionedUserIds,
            quotedMessageId: quotedMessageId,
            parentId: existing?.parentMessageId,
            showReplyInChannel: existing?.showReplyInChannel ?? false,
            extraData: extraData
        )
        repository.update(id: id, content: content, scheduledAt: scheduledAt) { result in
            self.callback { completion?(result) }
        }
    }

    /// Changes when a scheduled message is sent. A failed scheduled message is scheduled again.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - scheduledAt: When to send the message. At least 1 minute and at most 120 days from now.
    ///   - completion: Called when the message is rescheduled, with the scheduled message or an error.
    func rescheduleMessage(
        id: String,
        scheduledAt: Date,
        completion: (@MainActor (Result<ScheduledMessage, Error>) -> Void)? = nil
    ) {
        client.scheduledMessagesRepository.reschedule(id: id, scheduledAt: scheduledAt) { result in
            self.callback { completion?(result) }
        }
    }

    /// Deletes a scheduled message, so it is never sent.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - completion: Called when the message is deleted, with an error if it failed.
    func deleteScheduledMessage(id: String, completion: (@MainActor (Error?) -> Void)? = nil) {
        client.scheduledMessagesRepository.delete(id: id) { error in
            self.callback { completion?(error) }
        }
    }

    /// Sends a scheduled message right away.
    ///
    /// The message is added to the channel when it is sent, which is reported by the `ScheduledMessageSentEvent`.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - completion: Called when sending started, with an error if it failed.
    func sendScheduledMessageNow(id: String, completion: (@MainActor (Error?) -> Void)? = nil) {
        client.scheduledMessagesRepository.sendNow(id: id) { error in
            self.callback { completion?(error) }
        }
    }
}
