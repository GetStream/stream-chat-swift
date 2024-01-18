//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateChannelRequest: Codable, Hashable {
    public var cooldown: Int?
    
    public var removeMembers: [String]
    
    public var addModerators: [String]
    
    public var demoteModerators: [String]
    
    public var hideHistory: Bool?
    
    public var message: StreamChatMessageRequest?
    
    public var rejectInvite: Bool?
    
    public var skipPush: Bool?
    
    public var acceptInvite: Bool?
    
    public var addMembers: [StreamChatChannelMemberRequest?]?
    
    public var assignRoles: [StreamChatChannelMemberRequest?]?
    
    public var data: StreamChatChannelRequest?
    
    public var invites: [StreamChatChannelMemberRequest?]?
    
    public init(cooldown: Int?, removeMembers: [String], addModerators: [String], demoteModerators: [String], hideHistory: Bool?, message: StreamChatMessageRequest?, rejectInvite: Bool?, skipPush: Bool?, acceptInvite: Bool?, addMembers: [StreamChatChannelMemberRequest?]?, assignRoles: [StreamChatChannelMemberRequest?]?, data: StreamChatChannelRequest?, invites: [StreamChatChannelMemberRequest?]?) {
        self.cooldown = cooldown
        
        self.removeMembers = removeMembers
        
        self.addModerators = addModerators
        
        self.demoteModerators = demoteModerators
        
        self.hideHistory = hideHistory
        
        self.message = message
        
        self.rejectInvite = rejectInvite
        
        self.skipPush = skipPush
        
        self.acceptInvite = acceptInvite
        
        self.addMembers = addMembers
        
        self.assignRoles = assignRoles
        
        self.data = data
        
        self.invites = invites
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cooldown
        
        case removeMembers = "remove_members"
        
        case addModerators = "add_moderators"
        
        case demoteModerators = "demote_moderators"
        
        case hideHistory = "hide_history"
        
        case message
        
        case rejectInvite = "reject_invite"
        
        case skipPush = "skip_push"
        
        case acceptInvite = "accept_invite"
        
        case addMembers = "add_members"
        
        case assignRoles = "assign_roles"
        
        case data
        
        case invites
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(removeMembers, forKey: .removeMembers)
        
        try container.encode(addModerators, forKey: .addModerators)
        
        try container.encode(demoteModerators, forKey: .demoteModerators)
        
        try container.encode(hideHistory, forKey: .hideHistory)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(rejectInvite, forKey: .rejectInvite)
        
        try container.encode(skipPush, forKey: .skipPush)
        
        try container.encode(acceptInvite, forKey: .acceptInvite)
        
        try container.encode(addMembers, forKey: .addMembers)
        
        try container.encode(assignRoles, forKey: .assignRoles)
        
        try container.encode(data, forKey: .data)
        
        try container.encode(invites, forKey: .invites)
    }
}
