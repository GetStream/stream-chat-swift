//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension EndpointPath {
    var shouldBeQueuedOffline: Bool {
        switch self {
        case .addReaction,
             .deleteMessage,
             .deleteReaction,
             .draftMessage,
             .editMessage,
             .pinMessage,
             .sendMessage,
             .unpinMessage:
            return true
        case .banMember,
             .blockUsers,
             .callToken,
             .channelEvent,
             .channels,
             .channelUpdate,
             .connect,
             .createCall,
             .createChannel,
             .createDevice,
             .deleteChannel,
             .deleteDevice,
             .deleteFile,
             .deleteImage,
             .drafts,
             .flagMessage,
             .flagUser,
             .getApp,
             .getBlockedUsers,
             .getOG,
             .groupedChannels,
             .guest,
             .listDevices,
             .liveLocations,
             .markAllChannelsRead,
             .markChannelRead,
             .markChannelsDelivered,
             .markChannelUnread,
             .markThreadRead,
             .markThreadUnread,
             .members,
             .message,
             .messageAction,
             .muteChannel,
             .muteUser,
             .partialMemberUpdate,
             .pinnedMessages,
             .poll,
             .pollOption,
             .pollOptions,
             .polls,
             .pollsQuery,
             .pollVote,
             .pollVoteInMessage,
             .pollVotes,
             .pushPreferences,
             .reactions,
             .reminder,
             .reminders,
             .replies,
             .search,
             .searchRoles,
             .showChannel,
             .stopWatchingChannel,
             .sync,
             .thread,
             .threads,
             .translateMessage,
             .truncateChannel,
             .unblockUsers,
             .unread,
             .updateChannel,
             .uploadAttachment,
             .uploadChannelAttachment,
             .userGroup,
             .userGroupMembers,
             .userGroupMembersDelete,
             .userGroups,
             .userGroupSearch,
             .users:
            return false
        }
    }
}

extension Endpoint {
    var shouldBeQueuedOffline: Bool {
        path.shouldBeQueuedOffline
    }
}
