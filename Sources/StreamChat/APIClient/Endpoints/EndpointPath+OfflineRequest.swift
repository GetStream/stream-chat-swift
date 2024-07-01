//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension EndpointPath {
    var shouldBeQueuedOffline: Bool {
        switch self {
        case .sendMessage, .editMessage, .deleteMessage, .pinMessage, .unpinMessage, .addReaction, .deleteReaction:
            return true
        case .createChannel, .connect, .sync, .users, .guest, .members, .search, .devices, .channels, .updateChannel,
             .deleteChannel, .channelUpdate, .muteChannel, .showChannel, .truncateChannel, .markChannelRead, .markChannelUnread,
             .markAllChannelsRead, .channelEvent, .stopWatchingChannel, .pinnedMessages, .uploadAttachment, .message,
             .replies, .reactions, .messageAction, .banMember, .flagUser, .flagMessage, .muteUser, .translateMessage,
             .callToken, .createCall, .deleteFile, .deleteImage, .og, .appSettings, .threads, .thread, .markThreadRead, .markThreadUnread, .polls, .pollsQuery,
             .poll, .pollOption, .pollOptions, .pollVotes, .pollVoteInMessage, .pollVote, .unread, .blockUser, .unblockUser:
            return false
        }
    }
}

extension Endpoint {
    var shouldBeQueuedOffline: Bool {
        path.shouldBeQueuedOffline
    }
}
