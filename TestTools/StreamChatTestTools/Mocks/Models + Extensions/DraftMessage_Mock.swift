//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension DraftMessage {
    /// Creates a new `ChatMessage` object from the provided data.
    static func mock(
        id: MessageId = .unique,
        cid: ChannelId = .unique,
        threadId: MessageId? = nil,
        text: String = .unique,
        currentUser: ChatUser = .unique,
        command: String? = nil,
        createdAt: Date = Date(timeIntervalSince1970: 113),
        arguments: String? = nil,
        quotedMessage: ChatMessage? = nil,
        showReplyInChannel: Bool = false,
        extraData: [String: RawJSON] = [:],
        isSilent: Bool = false,
        mentionedUsers: Set<ChatUser> = [],
        attachments: [AnyChatMessageAttachment] = []
    ) -> Self {
        .init(
            id: id,
            cid: cid,
            threadId: threadId,
            text: text,
            isSilent: isSilent,
            command: command,
            createdAt: createdAt,
            arguments: arguments,
            showReplyInChannel: showReplyInChannel,
            extraData: extraData,
            currentUser: currentUser,
            quotedMessage: { quotedMessage },
            mentionedUsers: mentionedUsers,
            attachments: attachments
        )
    }
}
