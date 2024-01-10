//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateChannelRequest: Codable, Hashable {
    public var acceptInvite: Bool?
    
    public var addMembers: [StreamChatChannelMemberRequest?]?
    
    public var assignRoles: [StreamChatChannelMemberRequest?]?
    
    public var hideHistory: Bool?
    
    public var invites: [StreamChatChannelMemberRequest?]?
    
    public var data: StreamChatChannelRequest?
    
    public var skipPush: Bool?
    
    public var demoteModerators: [String]
    
    public var addModerators: [String]
    
    public var cooldown: Int?
    
    public var message: StreamChatMessageRequest?
    
    public var rejectInvite: Bool?
    
    public var removeMembers: [String]
    
    public init(acceptInvite: Bool?, addMembers: [StreamChatChannelMemberRequest?]?, assignRoles: [StreamChatChannelMemberRequest?]?, hideHistory: Bool?, invites: [StreamChatChannelMemberRequest?]?, data: StreamChatChannelRequest?, skipPush: Bool?, demoteModerators: [String], addModerators: [String], cooldown: Int?, message: StreamChatMessageRequest?, rejectInvite: Bool?, removeMembers: [String]) {
        self.acceptInvite = acceptInvite
        
        self.addMembers = addMembers
        
        self.assignRoles = assignRoles
        
        self.hideHistory = hideHistory
        
        self.invites = invites
        
        self.data = data
        
        self.skipPush = skipPush
        
        self.demoteModerators = demoteModerators
        
        self.addModerators = addModerators
        
        self.cooldown = cooldown
        
        self.message = message
        
        self.rejectInvite = rejectInvite
        
        self.removeMembers = removeMembers
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case acceptInvite = "accept_invite"
        
        case addMembers = "add_members"
        
        case assignRoles = "assign_roles"
        
        case hideHistory = "hide_history"
        
        case invites
        
        case data
        
        case skipPush = "skip_push"
        
        case demoteModerators = "demote_moderators"
        
        case addModerators = "add_moderators"
        
        case cooldown
        
        case message
        
        case rejectInvite = "reject_invite"
        
        case removeMembers = "remove_members"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(acceptInvite, forKey: .acceptInvite)
        
        try container.encode(addMembers, forKey: .addMembers)
        
        try container.encode(assignRoles, forKey: .assignRoles)
        
        try container.encode(hideHistory, forKey: .hideHistory)
        
        try container.encode(invites, forKey: .invites)
        
        try container.encode(data, forKey: .data)
        
        try container.encode(skipPush, forKey: .skipPush)
        
        try container.encode(demoteModerators, forKey: .demoteModerators)
        
        try container.encode(addModerators, forKey: .addModerators)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(rejectInvite, forKey: .rejectInvite)
        
        try container.encode(removeMembers, forKey: .removeMembers)
    }
}
