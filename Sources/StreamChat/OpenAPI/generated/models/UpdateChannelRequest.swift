//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateChannelRequest: Codable, Hashable {
    public var addModerators: [String]
    public var demoteModerators: [String]
    public var removeMembers: [String]
    public var acceptInvite: Bool? = nil
    public var cooldown: Int? = nil
    public var hideHistory: Bool? = nil
    public var rejectInvite: Bool? = nil
    public var skipPush: Bool? = nil
    public var addMembers: [ChannelMemberRequest?]? = nil
    public var assignRoles: [ChannelMemberRequest?]? = nil
    public var invites: [ChannelMemberRequest?]? = nil
    public var data: ChannelRequest? = nil
    public var message: MessageRequest? = nil

    public init(addModerators: [String], demoteModerators: [String], removeMembers: [String], acceptInvite: Bool? = nil, cooldown: Int? = nil, hideHistory: Bool? = nil, rejectInvite: Bool? = nil, skipPush: Bool? = nil, addMembers: [ChannelMemberRequest?]? = nil, assignRoles: [ChannelMemberRequest?]? = nil, invites: [ChannelMemberRequest?]? = nil, data: ChannelRequest? = nil, message: MessageRequest? = nil) {
        self.addModerators = addModerators
        self.demoteModerators = demoteModerators
        self.removeMembers = removeMembers
        self.acceptInvite = acceptInvite
        self.cooldown = cooldown
        self.hideHistory = hideHistory
        self.rejectInvite = rejectInvite
        self.skipPush = skipPush
        self.addMembers = addMembers
        self.assignRoles = assignRoles
        self.invites = invites
        self.data = data
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case addModerators = "add_moderators"
        case demoteModerators = "demote_moderators"
        case removeMembers = "remove_members"
        case acceptInvite = "accept_invite"
        case cooldown
        case hideHistory = "hide_history"
        case rejectInvite = "reject_invite"
        case skipPush = "skip_push"
        case addMembers = "add_members"
        case assignRoles = "assign_roles"
        case invites
        case data
        case message
    }
}
