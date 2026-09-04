//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension EndpointPath {
    var shouldBeQueuedOffline: Bool {
        switch self {
        case .createDraft,
             .deleteDraft,
             .deleteMessage,
             .deleteReaction,
             .sendMessage,
             .sendReaction,
             .updateMessage,
             .updateMessagePartial:
            return true
        case .addUserGroupMembers,
             .banMember,
             .blockUsers,
             .castPollVote,
             .channels,
             .channelUpdate,
             .connect,
             .custom,
             .createChannel,
             .createDevice,
             .createPoll,
             .createPollOption,
             .createReminder,
             .createUserGroup,
             .deleteChannel,
             .deleteChannelFile,
             .deleteChannelImage,
             .deleteDevice,
             .deleteFile,
             .deleteImage,
             .deletePoll,
             .deletePollVote,
             .deleteReminder,
             .deleteUserGroup,
             .flagMessage,
             .flagUser,
             .getApp,
             .getBlockedUsers,
             .getDraft,
             .getOG,
             .getPinnedMessages,
             .getReactions,
             .getReplies,
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
             .mute,
             .muteChannel,
             .queryDrafts,
             .queryMembers,
             .queryPollVotes,
             .queryReactions,
             .queryReminders,
             .queryUsers,
             .removeUserGroupMembers,
             .runMessageAction,
             .search,
             .searchRoles,
             .searchUserGroups,
             .sendEvent,
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
             .updateReminder,
             .updateUserGroup,
             .updateUsersPartial,
             .uploadChannelFile,
             .uploadChannelImage,
             .uploadFile,
             .uploadImage:
            return false
        }
    }
}

extension Endpoint {
    var shouldBeQueuedOffline: Bool {
        path.shouldBeQueuedOffline
    }
}
