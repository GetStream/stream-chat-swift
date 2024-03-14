//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateChannelRequest: Codable, Hashable {
    public var acceptInvite: Bool? = nil
    public var cooldown: Int? = nil
    public var hideHistory: Bool? = nil
    public var rejectInvite: Bool? = nil
    public var skipPush: Bool? = nil
    public var addMembers: [ChannelMemberRequest?]? = nil
    public var addModerators: [String]? = nil
    public var assignRoles: [ChannelMemberRequest?]? = nil
    public var demoteModerators: [String]? = nil
    public var invites: [ChannelMemberRequest?]? = nil
    public var removeMembers: [String]? = nil
    public var data: ChannelRequest? = nil
    public var message: MessageRequest? = nil

    public init(acceptInvite: Bool? = nil, cooldown: Int? = nil, hideHistory: Bool? = nil, rejectInvite: Bool? = nil, skipPush: Bool? = nil, addMembers: [ChannelMemberRequest?]? = nil, addModerators: [String]? = nil, assignRoles: [ChannelMemberRequest?]? = nil, demoteModerators: [String]? = nil, invites: [ChannelMemberRequest?]? = nil, removeMembers: [String]? = nil, data: ChannelRequest? = nil, message: MessageRequest? = nil) {
        self.acceptInvite = acceptInvite
        self.cooldown = cooldown
        self.hideHistory = hideHistory
        self.rejectInvite = rejectInvite
        self.skipPush = skipPush
        self.addMembers = addMembers
        self.addModerators = addModerators
        self.assignRoles = assignRoles
        self.demoteModerators = demoteModerators
        self.invites = invites
        self.removeMembers = removeMembers
        self.data = data
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case acceptInvite = "accept_invite"
        case cooldown
        case hideHistory = "hide_history"
        case rejectInvite = "reject_invite"
        case skipPush = "skip_push"
        case addMembers = "add_members"
        case addModerators = "add_moderators"
        case assignRoles = "assign_roles"
        case demoteModerators = "demote_moderators"
        case invites
        case removeMembers = "remove_members"
        case data
        case message
    }
}
