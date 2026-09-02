//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension EndpointPath: @retroactive Equatable {
    public static func == (_ lhs: EndpointPath, _ rhs: EndpointPath) -> Bool {
        switch (lhs, rhs) {
        case (.connect, .connect): return true
        case (.sync, .sync): return true
        case (.queryUsers, .queryUsers): return true
        case (.updateUsersPartial, .updateUsersPartial): return true
        case (.guest, .guest): return true
        case (.queryMembers, .queryMembers): return true
        case let (.updateMemberPartial(type1, id1), .updateMemberPartial(type2, id2)): return type1 == type2 && id1 == id2
        case (.search, .search): return true
        case (.createDevice, .createDevice): return true
        case (.deleteDevice, .deleteDevice): return true
        case (.listDevices, .listDevices): return true
        case (.channels, .channels): return true
        case let (.createChannel(string1), .createChannel(string2)): return string1 == string2
        case let (.updateChannel(string1), .updateChannel(string2)): return string1 == string2
        case let (.deleteChannel(type1, id1), .deleteChannel(type2, id2)): return type1 == type2 && id1 == id2
        case let (.channelUpdate(string1), .channelUpdate(string2)): return string1 == string2
        case let (.truncateChannel(type1, id1), .truncateChannel(type2, id2)): return type1 == type2 && id1 == id2
        case let (.markChannelRead(string1), .markChannelRead(string2)): return string1 == string2
        case (.markAllChannelsRead, .markAllChannelsRead): return true
        case let (.channelEvent(string1), .channelEvent(string2)): return string1 == string2
        case let (.stopWatchingChannel(type1, id1), .stopWatchingChannel(type2, id2)): return type1 == type2 && id1 == id2
        case let (.getPinnedMessages(type1, id1), .getPinnedMessages(type2, id2)): return type1 == type2 && id1 == id2
        case let (.sendMessage(type1, id1), .sendMessage(type2, id2)): return type1 == type2 && id1 == id2
        case let (.message(messageId1), .message(messageId2)): return messageId1 == messageId2
        case let (.updateMessage(messageId1), .updateMessage(messageId2)): return messageId1 == messageId2
        case let (.updateMessagePartial(messageId1), .updateMessagePartial(messageId2)): return messageId1 == messageId2
        case let (.createDraft(type1, id1), .createDraft(type2, id2)): return type1 == type2 && id1 == id2
        case let (.deleteMessage(messageId1), .deleteMessage(messageId2)): return messageId1 == messageId2
        case let (.getReplies(parentId1), .getReplies(parentId2)): return parentId1 == parentId2
        case let (.getReactions(messageId1), .getReactions(messageId2)): return messageId1 == messageId2
        case let (.queryReactions(messageId1), .queryReactions(messageId2)): return messageId1 == messageId2
        case let (.sendReaction(messageId1), .sendReaction(messageId2)): return messageId1 == messageId2
        case let (
            .deleteReaction(messageId1, type1),
            .deleteReaction(messageId2, type2)
        ): return messageId1 == messageId2 && type1 == type2
        case let (.runMessageAction(id1), .runMessageAction(id2)): return id1 == id2
        case (.banMember, .banMember): return true
        case (.flagUser, .flagUser): return true
        case (.flagMessage, .flagMessage): return true
        default: return false
        }
    }
}
