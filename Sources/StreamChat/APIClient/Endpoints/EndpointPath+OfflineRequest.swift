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
             .channelUpdate,
             .connect,
             .custom,
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
             .getOrCreateChannel,
             .getOrCreateDistinctChannel,
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
             .markChannelsRead,
             .markDelivered,
             .markRead,
             .markUnread,
             .message,
             .mute,
             .muteChannel,
             .queryChannels,
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
             .unban,
             .unblockUsers,
             .unmute,
             .unmuteChannel,
             .unreadCounts,
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
