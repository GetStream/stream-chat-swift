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
        case .addUserGroupMembers,
             .banMember,
             .blockUsers,
             .callToken,
             .channelEvent,
             .channels,
             .channelUpdate,
             .connect,
             .createCall,
             .createChannel,
             .createDevice,
             .createUserGroup,
             .deleteChannel,
             .deleteChannelFile,
             .deleteChannelImage,
             .deleteDevice,
             .deleteFile,
             .deleteImage,
             .deleteUserGroup,
             .drafts,
             .flagMessage,
             .flagUser,
             .getApp,
             .getBlockedUsers,
             .getOG,
             .getUserGroup,
             .getUserLiveLocations,
             .groupedChannels,
             .guest,
             .listDevices,
             .listUserGroups,
             .markAllChannelsRead,
             .markChannelRead,
             .markChannelsDelivered,
             .markChannelUnread,
             .markThreadRead,
             .markThreadUnread,
             .message,
             .messageAction,
             .muteChannel,
             .muteUser,
             .pinnedMessages,
             .poll,
             .pollOption,
             .pollOptions,
             .polls,
             .pollsQuery,
             .pollVote,
             .pollVoteInMessage,
             .pollVotes,
             .queryMembers,
             .reactions,
             .reminder,
             .reminders,
             .removeUserGroupMembers,
             .replies,
             .search,
             .searchRoles,
             .searchUserGroups,
             .showChannel,
             .stopWatchingChannel,
             .sync,
             .thread,
             .threads,
             .translateMessage,
             .truncateChannel,
             .unblockUsers,
             .unreadCounts,
             .updateChannel,
             .updateLiveLocation,
             .updateMemberPartial,
             .updatePushNotificationPreferences,
             .updateUserGroup,
             .uploadChannelFile,
             .uploadChannelImage,
             .uploadFile,
             .uploadImage,
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
