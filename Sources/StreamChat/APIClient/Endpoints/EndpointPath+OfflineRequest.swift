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
             .ban,
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
             .flag,
             .getApp,
             .getBlockedUsers,
             .getDraft,
             .getOG,
             .getPinnedMessages,
             .getReactions,
             .getReplies,
             .getThread,
             .getUserGroup,
             .getUserLiveLocations,
             .groupedChannels,
             .guest,
             .hideChannel,
             .listDevices,
             .listUserGroups,
             .markChannelsRead,
             .markDelivered,
             .markRead,
             .markUnread,
             .message,
             .mute,
             .muteChannel,
             .queryDrafts,
             .queryMembers,
             .queryPollVotes,
             .queryReactions,
             .queryReminders,
             .queryThreads,
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
             .translateMessage,
             .truncateChannel,
             .unban,
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
             .updateThreadPartial,
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
