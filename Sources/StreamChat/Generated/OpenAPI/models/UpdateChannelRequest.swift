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
    /// List of user IDs to remove from the channel
    let removeMembers: [String]?

    init(
        acceptInvite: Bool? = nil,
        addFilterTags: [String]? = nil,
        addMembers: [ChannelMemberRequest]? = nil,
        data: ChannelInputRequest? = nil,
        hideHistory: Bool? = nil,
        hideHistoryBefore: Date? = nil,
        invites: [ChannelMemberRequest]? = nil,
        message: MessageRequest? = nil,
        rejectInvite: Bool? = nil,
        removeMembers: [String]? = nil
    ) {
        self.acceptInvite = acceptInvite
        self.addFilterTags = addFilterTags
        self.addMembers = addMembers
        self.data = data
        self.hideHistory = hideHistory
        self.hideHistoryBefore = hideHistoryBefore
        self.invites = invites
        self.message = message
        self.rejectInvite = rejectInvite
        self.removeMembers = removeMembers
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(acceptInvite, forKey: .acceptInvite)
        try container.encodeIfPresent(addFilterTags, forKey: .addFilterTags)
        try container.encodeIfPresent(addMembers, forKey: .addMembers)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(hideHistory, forKey: .hideHistory)
        try container.encodeIfPresent(hideHistoryBefore, forKey: .hideHistoryBefore)
        try container.encodeIfPresent(invites, forKey: .invites)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(rejectInvite, forKey: .rejectInvite)
        try container.encodeIfPresent(removeMembers, forKey: .removeMembers)
    }
}
