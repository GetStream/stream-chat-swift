//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension EndpointPath {
    var shouldBeQueuedOffline: Bool {
        switch self {
        case .sendMessage, .editMessage, .deleteMessage, .pinMessage, .unpinMessage, .addReaction, .deleteReaction, .draftMessage:
            return true
        case .createChannel, .connect, .sync, .users, .guest, .members, .partialMemberUpdate, .search, .createDevice, .deleteDevice, .listDevices, .channels, .groupedChannels, .updateChannel,
             .deleteChannel, .channelUpdate, .muteChannel, .showChannel, .truncateChannel, .markChannelRead, .markChannelUnread,
             .markAllChannelsRead, .markChannelsDelivered, .channelEvent, .stopWatchingChannel, .pinnedMessages, .uploadChannelAttachment, .message,
             .replies, .reactions, .messageAction, .banMember, .flagUser, .flagMessage, .muteUser, .translateMessage,
             .callToken, .createCall, .deleteFile, .deleteImage, .getOG, .getApp, .threads, .thread, .markThreadRead, .markThreadUnread,
             .polls, .pollsQuery, .poll, .pollOption, .pollOptions, .pollVotes, .pollVoteInMessage, .pollVote,
             .unread, .blockUsers, .unblockUsers, .getBlockedUsers, .drafts, .reminders, .reminder, .liveLocations, .uploadAttachment, .pushPreferences,
             .listUserGroups, .searchUserGroups, .getUserGroup, .createUserGroup, .updateUserGroup, .deleteUserGroup, .addUserGroupMembers, .removeUserGroupMembers,
             .rolesSearch:
            return false
        }
    }
}

extension Endpoint {
    var shouldBeQueuedOffline: Bool {
        path.shouldBeQueuedOffline
    }
}
