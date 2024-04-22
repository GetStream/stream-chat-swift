//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension ChatState {
    struct UnreadMessageLookup {
        let userId: UserId
        let readStates: [ChatChannelRead]
        let messageOrder: MessageOrdering
        let messages: StreamCollection<ChatMessage>
        let hasLoadedAllOlderMessages: Bool
        
        @MainActor static func firstUnreadMessage(in state: ChatState, userId: UserId) -> MessageId? {
            guard let channel = state.channel else { return nil }
            let lookup = UnreadMessageLookup(
                userId: userId,
                readStates: channel.reads,
                messageOrder: state.messageOrder,
                messages: state.messages,
                hasLoadedAllOlderMessages: state.hasLoadedAllOlderMessages
            )
            return lookup.firstUnreadMessageId
        }
        
        private var firstUnreadMessageId: MessageId? {
            guard let readInfo = readStates.first(where: { $0.user.id == userId }) else {
                // Read state is unavailable
                return hasLoadedAllOlderMessages ? oldestRegularMessageId : nil
            }
            guard readInfo.unreadMessagesCount > 0 else { return nil }
            guard let lastReadMessageId = readInfo.lastReadMessageId else {
                // Everything is unread if read state is there but there is no lastReadMessageId
                return hasLoadedAllOlderMessages ? oldestRegularMessageId : nil
            }
            if let lastReadIndex = indexOfMessageId(lastReadMessageId) {
                if isMostRecent(at: lastReadIndex) {
                    // Everything has been read
                    return nil
                } else {
                    return lookupUnreadMessageId(after: lastReadIndex)
                }
            } else {
                // Can't reach the last read message (if all have been loaded then the channel might have been truncated or hidden, in that case, use the oldest message)
                return hasLoadedAllOlderMessages ? oldestRegularMessageId : nil
            }
        }
        
        private func lookupUnreadMessageId(after excludedSearchIndex: Int) -> MessageId? {
            let searchRange: ReversedCollection<Range<Int>> = {
                if messageOrder.isAscending {
                    return (messages.endIndex..<excludedSearchIndex).reversed()
                } else {
                    return (messages.startIndex..<excludedSearchIndex).reversed()
                }
            }()
            for index in searchRange {
                if let message = messages[safe: index], message.deletedAt == nil, message.author.id != userId {
                    return message.id
                }
            }
            return nil
        }
        
        private func indexOfMessageId(_ messageId: MessageId) -> Int? {
            messages.firstIndex(where: { $0.id == messageId })
        }
        
        private func isMostRecent(at index: Int) -> Bool {
            if messageOrder.isAscending {
                return messages.index(before: messages.endIndex) == index
            } else {
                return messages.startIndex == index
            }
        }
        
        private var oldestRegularMessageId: MessageId? {
            if messageOrder.isAscending {
                return messages.first(where: \.isRegular)?.id
            } else {
                return messages.last(where: \.isRegular)?.id
            }
        }
    }
}

private extension ChatMessage {
    var isRegular: Bool {
        switch type {
        case .regular, .reply:
            return true
        case .deleted, .ephemeral, .error, .system:
            return false
        }
    }
}
