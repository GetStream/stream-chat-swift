//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension EndpointPath {
    var shouldBeQueuedOffline: Bool {
        switch self {
        case .createChannel, .sendMessage, .editMessage, .deleteMessage, .addReaction, .deleteReaction:
            return true
        case .connect, .sync, .users, .guest, .members, .search, .devices, .channels, .updateChannel, .deleteChannel,
             .channelUpdate, .muteChannel, .showChannel, .truncateChannel, .markChannelRead, .markAllChannelsRead,
             .channelEvent, .stopWatchingChannel, .pinnedMessages, .uploadAttachment, .message, .replies, .reactions,
             .messageAction, .banMember, .flagUser, .flagMessage, .muteUser:
            return false
        }
    }
}

extension Endpoint {
    var shouldBeQueuedOffline: Bool {
        path.shouldBeQueuedOffline
    }
}
