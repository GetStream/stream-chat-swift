//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateChannelRequest: Codable, Hashable {
    public var addMembers: [StreamChatChannelMemberRequest?]?
    
    public var addModerators: [String]
    
    public var cooldown: Int?
    
    public var hideHistory: Bool?
    
    public var message: StreamChatMessageRequest?
    
    public var assignRoles: [StreamChatChannelMemberRequest?]?
    
    public var data: StreamChatChannelRequest?
    
    public var rejectInvite: Bool?
    
    public var acceptInvite: Bool?
    
    public var demoteModerators: [String]
    
    public var removeMembers: [String]
    
    public var userId: String?
    
    public var invites: [StreamChatChannelMemberRequest?]?
    
    public var skipPush: Bool?
    
    public var user: StreamChatUserObjectRequest?
    
    public init(addMembers: [StreamChatChannelMemberRequest?]?, addModerators: [String], cooldown: Int?, hideHistory: Bool?, message: StreamChatMessageRequest?, assignRoles: [StreamChatChannelMemberRequest?]?, data: StreamChatChannelRequest?, rejectInvite: Bool?, acceptInvite: Bool?, demoteModerators: [String], removeMembers: [String], userId: String?, invites: [StreamChatChannelMemberRequest?]?, skipPush: Bool?, user: StreamChatUserObjectRequest?) {
        self.addMembers = addMembers
        
        self.addModerators = addModerators
        
        self.cooldown = cooldown
        
        self.hideHistory = hideHistory
        
        self.message = message
        
        self.assignRoles = assignRoles
        
        self.data = data
        
        self.rejectInvite = rejectInvite
        
        self.acceptInvite = acceptInvite
        
        self.demoteModerators = demoteModerators
        
        self.removeMembers = removeMembers
        
        self.userId = userId
        
        self.invites = invites
        
        self.skipPush = skipPush
        
        self.user = user
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case addMembers = "add_members"
        
        case addModerators = "add_moderators"
        
        case cooldown
        
        case hideHistory = "hide_history"
        
        case message
        
        case assignRoles = "assign_roles"
        
        case data
        
        case rejectInvite = "reject_invite"
        
        case acceptInvite = "accept_invite"
        
        case demoteModerators = "demote_moderators"
        
        case removeMembers = "remove_members"
        
        case userId = "user_id"
        
        case invites
        
        case skipPush = "skip_push"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(addMembers, forKey: .addMembers)
        
        try container.encode(addModerators, forKey: .addModerators)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(hideHistory, forKey: .hideHistory)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(assignRoles, forKey: .assignRoles)
        
        try container.encode(data, forKey: .data)
        
        try container.encode(rejectInvite, forKey: .rejectInvite)
        
        try container.encode(acceptInvite, forKey: .acceptInvite)
        
        try container.encode(demoteModerators, forKey: .demoteModerators)
        
        try container.encode(removeMembers, forKey: .removeMembers)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(invites, forKey: .invites)
        
        try container.encode(skipPush, forKey: .skipPush)
        
        try container.encode(user, forKey: .user)
    }
}
