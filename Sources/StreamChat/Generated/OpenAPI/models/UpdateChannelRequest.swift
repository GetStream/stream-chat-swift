//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateChannelRequest: Sendable, Encodable, JSONEncodable {
    /// Set to `true` to accept the invite
    let acceptInvite: Bool?
    /// List of filter tags to add to the channel
    let addFilterTags: [String]?
    /// List of user IDs to add to the channel
    let addMembers: [ChannelMemberRequest]?
    /// Sets cool down period for the channel in seconds
    let cooldown: Int?
    let data: ChannelInputRequest?
    /// Set to `true` to hide channel's history when adding new members
    let hideHistory: Bool?
    /// If set, hides channel's history before this time when adding new members. Takes precedence over `hide_history` when both are provided. Must be in RFC3339 format (e.g., "2024-01-01T10:00:00Z") and in the past.
    let hideHistoryBefore: Date?
    /// List of user IDs to invite to the channel
    let invites: [ChannelMemberRequest]?
    /// Message data for creating or updating a message
    let message: MessageRequest?
    /// Set to `true` to reject the invite
    let rejectInvite: Bool?
    /// List of filter tags to remove from the channel
    let removeFilterTags: [String]?
    /// List of user IDs to remove from the channel
    let removeMembers: [String]?
    /// When `message` is set disables all push notifications for it
    let skipPush: Bool?

    init(
        acceptInvite: Bool? = nil,
        addFilterTags: [String]? = nil,
        addMembers: [ChannelMemberRequest]? = nil,
        cooldown: Int? = nil,
        data: ChannelInputRequest? = nil,
        hideHistory: Bool? = nil,
        hideHistoryBefore: Date? = nil,
        invites: [ChannelMemberRequest]? = nil,
        message: MessageRequest? = nil,
        rejectInvite: Bool? = nil,
        removeFilterTags: [String]? = nil,
        removeMembers: [String]? = nil,
        skipPush: Bool? = nil
    ) {
        self.acceptInvite = acceptInvite
        self.addFilterTags = addFilterTags
        self.addMembers = addMembers
        self.cooldown = cooldown
        self.data = data
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
        case cooldown
        case data
        case hideHistory = "hide_history"
        case hideHistoryBefore = "hide_history_before"
        case invites
        case message
        case rejectInvite = "reject_invite"
        case removeFilterTags = "remove_filter_tags"
        case removeMembers = "remove_members"
        case skipPush = "skip_push"
    }
}
