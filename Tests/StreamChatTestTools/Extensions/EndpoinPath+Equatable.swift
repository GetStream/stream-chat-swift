//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension EndpointPath: Equatable {
    static public func == (_ lhs: EndpointPath, _ rhs: EndpointPath) -> Bool {
        switch (lhs, rhs) {
        case (.connect, .connect): return true
        case (.sync, .sync): return true
        case (.users, .users): return true
        case (.guest, .guest): return true
        case (.members, .members): return true
        case (.search, .search): return true
        case (.devices, .devices): return true
        case (.channels, .channels): return true
        case let (.createChannel(string1), .createChannel(string2)): return string1 == string2
        case let (.updateChannel(string1), .updateChannel(string2)): return string1 == string2
        case let (.deleteChannel(string1), .deleteChannel(string2)): return string1 == string2
        case let (.channelUpdate(string1), .channelUpdate(string2)): return string1 == string2
        case let (.muteChannel(bool1), .muteChannel(bool2)): return bool1 == bool2
        case let (.showChannel(string1, bool1), .showChannel(string2, bool2)): return string1 == string2 && bool1 == bool2
        case let (.truncateChannel(string1), .truncateChannel(string2)): return string1 == string2
        case let (.markChannelRead(string1), .markChannelRead(string2)): return string1 == string2
        case (.markAllChannelsRead, .markAllChannelsRead): return true
        case let (.channelEvent(string1), .channelEvent(string2)): return string1 == string2
        case let (.stopWatchingChannel(string1), .stopWatchingChannel(string2)): return string1 == string2
        case let (.pinnedMessages(string1), .pinnedMessages(string2)): return string1 == string2
        case let (.uploadAttachment(channelId1, type1), .uploadAttachment(channelId2, type2)): return channelId1 == channelId2 &&
            type1 ==
            type2
        case let (.sendMessage(channelId1), .sendMessage(channelId2)): return channelId1 == channelId2
        case let (.message(messageId1), .message(messageId2)): return messageId1 == messageId2
        case let (.editMessage(messageId1), .editMessage(messageId2)): return messageId1 == messageId2
        case let (.deleteMessage(messageId1), .deleteMessage(messageId2)): return messageId1 == messageId2
        case let (.replies(messageId1), .replies(messageId2)): return messageId1 == messageId2
        case let (.reactions(messageId1), .reactions(messageId2)): return messageId1 == messageId2
        case let (.addReaction(messageId1), .addReaction(messageId2)): return messageId1 == messageId2
        case let (
            .deleteReaction(messageId1, messageReactionType1),
            .deleteReaction(messageId2, messageReactionType2)
        ): return messageId1 == messageId2 && messageReactionType1 ==
            messageReactionType2
        case let (.messageAction(messageId1), .messageAction(messageId2)): return messageId1 == messageId2
        case (.banMember, .banMember): return true
        case let (.flagUser(bool1), .flagUser(bool2)): return bool1 == bool2
        case let (.flagMessage(bool1), .flagMessage(bool2)): return bool1 == bool2
        case let (.muteUser(bool1), .muteUser(bool2)): return bool1 == bool2
        default: return false
        }
    }
}
