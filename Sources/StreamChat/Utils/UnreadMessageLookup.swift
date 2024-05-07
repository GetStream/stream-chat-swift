//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

enum UnreadMessageLookup {
    static func firstUnreadMessageId(
        in channel: ChatChannel,
        messages: StreamCollection<ChatMessage>,
        hasLoadedAllPreviousMessages: Bool,
        currentUserId: UserId?
    ) -> MessageId? {
        // Return the oldest regular message if all messages are unread in the message list.
        let oldestRegularMessage: () -> MessageId? = {
            guard hasLoadedAllPreviousMessages == true else {
                return nil
            }
            return messages.last(where: { $0.type == .regular || $0.type == .reply })?.id
        }

        guard let currentUserRead = channel.reads.first(where: {
            $0.user.id == currentUserId
        }) else {
            return oldestRegularMessage()
        }

        // If there are no unreads, then return nil.
        guard currentUserRead.unreadMessagesCount > 0 else {
            return nil
        }

        // If there unreads but no `lastReadMessageId`, it means the whole message list is unread.
        // So the top message (oldest one) is the first unread message id.
        guard let lastReadMessageId = currentUserRead.lastReadMessageId else {
            return oldestRegularMessage()
        }

        guard lastReadMessageId != messages.first?.id else {
            return nil
        }

        guard let lastReadIndex = messages.firstIndex(where: { $0.id == lastReadMessageId }), lastReadIndex != 0 else {
            // If there is a lastReadMessageId, and we loaded all messages, but can't find firstUnreadMessageId,
            // then it means the lastReadMessageId is not reachable because the channel was truncated or hidden.
            // So we return the oldest regular message already fetched.
            if hasLoadedAllPreviousMessages {
                return oldestRegularMessage()
            }

            return nil
        }

        let lookUpStartIndex = messages.index(before: lastReadIndex)

        var id: MessageId?
        for index in (0...lookUpStartIndex).reversed() {
            let message = messages[safe: index]
            guard message?.author.id != currentUserId, message?.deletedAt == nil else { continue }
            id = message?.id
            break
        }

        return id
    }
}
