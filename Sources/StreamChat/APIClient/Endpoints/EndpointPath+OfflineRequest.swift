//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension EndpointPath {
    var shouldBeQueuedOffline: Bool {
        switch self {
        case .connect: return false
        case .sync: return false
        case .users: return true // When it is a PATCH - Needs DB Action
        case .guest: return false
        case .members: return false
        case .search: return false
        case .devices: return true // When it is a POST / DELETE - Needs DB Action
        case .channels: return false
        case .channelsQuery: return true // Needs DB Action
        case .deleteChannel: return true // Needs DB Action
        case .channelUpdate: return true
        case .muteChannel: return true
        case .showChannel: return true // Needs DB Action
        case .truncateChannel: return true
        case .markChannelRead: return true // Needs DB Action
        case .markAllChannelsRead: return true
        case .channelEvent: return false
        case .stopWatchingChannel: return true
        case .pinnedMessages: return false
        case .uploadAttachment: return true // Needs DB Action
        case .sendMessage: return true // Needs DB Action
        case .message: return false
        case .editMessage: return true // Needs DB Action
        case .deleteMessage: return true // Needs DB Action
        case .replies: return false
        case .reactions: return false
        case .reaction: return true // Needs DB Action
        case .deleteReaction: return true // Needs DB Action
        case .messageAction: return true // Needs DB Action
        case .banMember: return true
        case .flagUser: return true // Needs DB Action
        case .flagMessage: return true // Needs DB Action
        case .muteUser: return false
        }
    }

    var queuedRequestNeedsDatabaseAction: Bool {
        switch self {
        case .users: return true
        case .devices: return true
        case .channelsQuery: return true
        case .deleteChannel: return true
        case .channelUpdate: return false
        case .muteChannel: return false
        case .showChannel: return true
        case .truncateChannel: return false
        case .markChannelRead: return true
        case .markAllChannelsRead: return true
        case .stopWatchingChannel: return true
        case .uploadAttachment: return true
        case .sendMessage: return true
        case .editMessage: return true
        case .deleteMessage: return true
        case .reaction: return true
        case .deleteReaction: return true
        case .messageAction: return true
        case .banMember: return false
        case .flagUser: return true
        case .flagMessage: return true
        default: return false
        }
    }
}
