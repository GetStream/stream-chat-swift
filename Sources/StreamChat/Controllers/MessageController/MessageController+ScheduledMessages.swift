//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public extension ChatMessageController {
    /// Schedules a new reply to the message, to be sent at a later date.
    ///
    /// The reply is not added to the thread until it is sent. Local attachments are uploaded when scheduling.
    ///
    /// - Parameters:
    ///   - messageId: The id of the scheduled message. Scheduling twice with the same id returns the existing scheduled message.
    ///   - text: Text of the reply.
    ///   - attachments: An array of the attachments for the reply.
    ///   - mentionedUserIds: An array of the users mentioned in the reply.
    ///   - showReplyInChannel: Set this flag to `true` if you want the reply to be shown in the channel as well.
    ///   - quotedMessageId: An id of the message the reply quotes.
    ///   - extraData: Additional extra data of the reply.
    ///   - scheduledAt: When to send the reply, at most 120 days from now. The server rounds it up to the next whole minute,
    ///   at least 1 minute from now. A date in the past sends the reply right away.
    ///   - completion: Called when the reply is saved locally, with the scheduled message or an error. It is sent
    ///   to the server once its attachments are uploaded, see `ScheduledMessage.status`.
    func scheduleReply(
        messageId: MessageId? = nil,
        text: String,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        showReplyInChannel: Bool = false,
        quotedMessageId: MessageId? = nil,
        extraData: [String: RawJSON] = [:],
        scheduledAt: Date,
        completion: (@MainActor (Result<ScheduledMessage, Error>) -> Void)? = nil
    ) {
        let content = ScheduledMessageContent(
            text: text,
            attachments: attachments,
            mentionedUserIds: mentionedUserIds,
            quotedMessageId: quotedMessageId,
            parentId: self.messageId,
            showReplyInChannel: showReplyInChannel,
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

    /// Updates the content of a scheduled reply to the message, and optionally when it is sent.
    ///
    /// A failed scheduled reply can not be changed: delete it and schedule a new one.
    ///
    /// - Parameters:
    ///   - id: The id of the scheduled message.
    ///   - text: The new text of the reply.
    ///   - attachments: The new attachments of the reply.
    ///   - mentionedUserIds: The new mentioned users of the reply.
    ///   - showReplyInChannel: Set this flag to `true` if you want the reply to be shown in the channel as well.
    ///   - quotedMessageId: The new quoted message of the reply.
    ///   - extraData: The new extra data of the reply.
    ///   - scheduledAt: When to send the reply, not in the past. The server rounds it up to the next whole minute.
    ///   `nil` keeps the current date.
    ///   - completion: Called when the reply is updated locally, with the scheduled message or an error. The changes are
    ///   sent to the server once its attachments are uploaded, see `ScheduledMessage.status`.
    func updateScheduledReply(
        id: String,
        text: String,
        attachments: [AnyAttachmentPayload] = [],
        mentionedUserIds: [UserId] = [],
        showReplyInChannel: Bool = false,
        quotedMessageId: MessageId? = nil,
        extraData: [String: RawJSON] = [:],
        scheduledAt: Date? = nil,
        completion: (@MainActor (Result<ScheduledMessage, Error>) -> Void)? = nil
    ) {
        let content = ScheduledMessageContent(
            text: text,
            attachments: attachments,
            mentionedUserIds: mentionedUserIds,
            quotedMessageId: quotedMessageId,
            parentId: messageId,
            showReplyInChannel: showReplyInChannel,
            extraData: extraData
        )
        client.scheduledMessagesRepository.update(id: id, content: content, scheduledAt: scheduledAt) { result in
            self.callback { completion?(result) }
        }
    }
}
