//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateChannelRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Set to `true` to accept the invite
    var acceptInvite: Bool?
    /// List of filter tags to add to the channel
    var addFilterTags: [String]?
    /// List of user IDs to add to the channel
    var addMembers: [ChannelMemberRequest]?
    /// List of user IDs to make channel moderators
    var addModerators: [String]?
    /// List of channel member role assignments. If any specified user is not part of the channel, the request will fail
    var assignRoles: [ChannelMemberRequest]?
    /// Sets cool down period for the channel in seconds
    var cooldown: Int?
    var data: ChannelInputRequest?
    /// List of user IDs to take away moderators status from
    var demoteModerators: [String]?
    /// Set to `true` to hide channel's history when adding new members
    var hideHistory: Bool?
    /// If set, hides channel's history before this time when adding new members. Takes precedence over `hide_history` when both are provided. Must be in RFC3339 format (e.g., "2024-01-01T10:00:00Z") and in the past.
    var hideHistoryBefore: Date?
    /// List of user IDs to invite to the channel
    var invites: [ChannelMemberRequest]?
    var message: MessageRequest?
    /// Set to `true` to reject the invite
    var rejectInvite: Bool?
    /// List of filter tags to remove from the channel
    var removeFilterTags: [String]?
    /// List of user IDs to remove from the channel
    var removeMembers: [String]?
    /// When `message` is set disables all push notifications for it
    var skipPush: Bool?

    init(acceptInvite: Bool? = nil, addFilterTags: [String]? = nil, addMembers: [ChannelMemberRequest]? = nil, addModerators: [String]? = nil, assignRoles: [ChannelMemberRequest]? = nil, cooldown: Int? = nil, data: ChannelInputRequest? = nil, demoteModerators: [String]? = nil, hideHistory: Bool? = nil, hideHistoryBefore: Date? = nil, invites: [ChannelMemberRequest]? = nil, message: MessageRequest? = nil, rejectInvite: Bool? = nil, removeFilterTags: [String]? = nil, removeMembers: [String]? = nil, skipPush: Bool? = nil) {
        self.acceptInvite = acceptInvite
        self.addFilterTags = addFilterTags
        self.addMembers = addMembers
        self.addModerators = addModerators
        self.assignRoles = assignRoles
        self.cooldown = cooldown
        self.data = data
        self.demoteModerators = demoteModerators
        self.hideHistory = hideHistory
        self.hideHistoryBefore = hideHistoryBefore
        self.invites = invites
        self.message = message
        self.rejectInvite = rejectInvite
        self.removeFilterTags = removeFilterTags
        self.removeMembers = removeMembers
        self.skipPush = skipPush
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case acceptInvite = "accept_invite"
        case addFilterTags = "add_filter_tags"
        case addMembers = "add_members"
        case addModerators = "add_moderators"
        case assignRoles = "assign_roles"
        case cooldown
        case data
        case demoteModerators = "demote_moderators"
        case hideHistory = "hide_history"
        case hideHistoryBefore = "hide_history_before"
        case invites
        case message
        case rejectInvite = "reject_invite"
        case removeFilterTags = "remove_filter_tags"
        case removeMembers = "remove_members"
        case skipPush = "skip_push"
    }

    static func == (lhs: UpdateChannelRequest, rhs: UpdateChannelRequest) -> Bool {
        lhs.acceptInvite == rhs.acceptInvite &&
            lhs.addFilterTags == rhs.addFilterTags &&
            lhs.addMembers == rhs.addMembers &&
            lhs.addModerators == rhs.addModerators &&
            lhs.assignRoles == rhs.assignRoles &&
            lhs.cooldown == rhs.cooldown &&
            lhs.data == rhs.data &&
            lhs.demoteModerators == rhs.demoteModerators &&
            lhs.hideHistory == rhs.hideHistory &&
            lhs.hideHistoryBefore == rhs.hideHistoryBefore &&
            lhs.invites == rhs.invites &&
            lhs.message == rhs.message &&
            lhs.rejectInvite == rhs.rejectInvite &&
            lhs.removeFilterTags == rhs.removeFilterTags &&
            lhs.removeMembers == rhs.removeMembers &&
            lhs.skipPush == rhs.skipPush
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(acceptInvite)
        hasher.combine(addFilterTags)
        hasher.combine(addMembers)
        hasher.combine(addModerators)
        hasher.combine(assignRoles)
        hasher.combine(cooldown)
        hasher.combine(data)
        hasher.combine(demoteModerators)
        hasher.combine(hideHistory)
        hasher.combine(hideHistoryBefore)
        hasher.combine(invites)
        hasher.combine(message)
        hasher.combine(rejectInvite)
        hasher.combine(removeFilterTags)
        hasher.combine(removeMembers)
        hasher.combine(skipPush)
    }
}
