//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension EndpointPath {
    var shouldBeQueuedOffline: Bool {
        switch self {
        case .createDraft,
             .deleteMessage,
             .deleteReaction,
             .draftMessage,
             .sendMessage,
             .sendReaction,
             .updateMessage,
             .updateMessagePartial:
            return true
        case .addUserGroupMembers,
             .banMember,
             .blockUsers,
             .castPollVote,
             .channelEvent,
             .channels,
             .channelUpdate,
             .connect,
             .custom,
             .createChannel,
             .createDevice,
             .createPoll,
             .createPollOption,
             .createUserGroup,
             .deleteChannel,
             .deleteChannelFile,
             .deleteChannelImage,
             .deleteDevice,
             .deleteFile,
             .deleteImage,
             .deletePoll,
             .deletePollVote,
             .deleteUserGroup,
             .drafts,
             .flagMessage,
             .flagUser,
             .getApp,
             .getBlockedUsers,
             .getOG,
             .getReactions,
             .getUserGroup,
             .getUserLiveLocations,
             .groupedChannels,
             .guest,
             .hideChannel,
             .listDevices,
             .listUserGroups,
             .markAllChannelsRead,
             .markChannelRead,
             .markChannelUnread,
             .markDelivered,
             .markThreadRead,
             .markThreadUnread,
             .message,
             .messageAction,
             .mute,
             .muteChannel,
             .pinnedMessages,
             .queryMembers,
             .queryPollVotes,
             .queryReactions,
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
             .unmute,
             .unmuteChannel,
             .unreadCounts,
             .updateChannel,
             .updateLiveLocation,
             .updateMemberPartial,
             .updatePollPartial,
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
