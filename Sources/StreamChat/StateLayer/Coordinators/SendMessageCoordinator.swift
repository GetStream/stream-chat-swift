//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A coordinator managing the send message flow by writing a message to a local database and then waiting for the message sending request.
@available(iOS 13.0, *)
final class SendMessageCoordinator {
    private let channelUpdater: ChannelUpdater
    private let eventNotificationCenter: EventNotificationCenter
    private let messageSender: MessageSender
    
    init(channelUpdater: ChannelUpdater, eventNotificationCenter: EventNotificationCenter, messageSender: MessageSender) {
        self.channelUpdater = channelUpdater
        self.eventNotificationCenter = eventNotificationCenter
        self.messageSender = messageSender
    }
    
    func sendMessage(
        with text: String,
        in channel: ChannelId,
        attachments: [AnyAttachmentPayload] = [],
        messageId: MessageId? = nil,
        mentionedUserIds: [UserId] = [],
        quotedMessageId: MessageId? = nil,
        pinning: MessagePinning? = nil,
        silent: Bool = false,
        skipPush: Bool = false,
        skipEnrichUrl: Bool = false,
        extraData: [String: RawJSON] = [:]
    ) async throws -> ChatMessage {
        let message = try await channelUpdater.createNewMessage(
            in: channel,
            messageId: messageId,
            text: text,
            pinning: pinning,
            isSilent: silent,
            command: nil,
            arguments: nil,
            attachments: attachments,
            mentionedUserIds: mentionedUserIds,
            quotedMessageId: quotedMessageId,
            skipPush: skipPush,
            skipEnrichUrl: skipEnrichUrl,
            extraData: extraData
        )
        eventNotificationCenter.process(NewMessagePendingEvent(message: message))
        return try await messageSender.waitForAPIRequest(messageId: message.id)
    }
}
