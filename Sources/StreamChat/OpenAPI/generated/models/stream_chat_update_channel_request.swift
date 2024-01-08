//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateChannelRequest: Codable, Hashable {
    public var addMembers: [StreamChatChannelMemberRequest?]?
    
    public var addModerators: [String]
    
    public var demoteModerators: [String]
    
    public var hideHistory: Bool?
    
    public var removeMembers: [String]
    
    public var skipPush: Bool?
    
    public var assignRoles: [StreamChatChannelMemberRequest?]?
    
    public var cooldown: Int?
    
    public var message: StreamChatMessageRequest?
    
    public var acceptInvite: Bool?
    
    public var data: StreamChatChannelRequest?
    
    public var invites: [StreamChatChannelMemberRequest?]?
    
    public var rejectInvite: Bool?
    
    public init(addMembers: [StreamChatChannelMemberRequest?]?, addModerators: [String], demoteModerators: [String], hideHistory: Bool?, removeMembers: [String], skipPush: Bool?, assignRoles: [StreamChatChannelMemberRequest?]?, cooldown: Int?, message: StreamChatMessageRequest?, acceptInvite: Bool?, data: StreamChatChannelRequest?, invites: [StreamChatChannelMemberRequest?]?, rejectInvite: Bool?) {
        self.addMembers = addMembers
        
        self.addModerators = addModerators
        
        self.demoteModerators = demoteModerators
        
        self.hideHistory = hideHistory
        
        self.removeMembers = removeMembers
        
        self.skipPush = skipPush
        
        self.assignRoles = assignRoles
        
        self.cooldown = cooldown
        
        self.message = message
        
        self.acceptInvite = acceptInvite
        
        self.data = data
        
        self.invites = invites
        
        self.rejectInvite = rejectInvite
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case addMembers = "add_members"
        
        case addModerators = "add_moderators"
        
        case demoteModerators = "demote_moderators"
        
        case hideHistory = "hide_history"
        
        case removeMembers = "remove_members"
        
        case skipPush = "skip_push"
        
        case assignRoles = "assign_roles"
        
        case cooldown
        
        case message
        
        case acceptInvite = "accept_invite"
        
        case data
        
        case invites
        
        case rejectInvite = "reject_invite"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(addMembers, forKey: .addMembers)
        
        try container.encode(addModerators, forKey: .addModerators)
        
        try container.encode(demoteModerators, forKey: .demoteModerators)
        
        try container.encode(hideHistory, forKey: .hideHistory)
        
        try container.encode(removeMembers, forKey: .removeMembers)
        
        try container.encode(skipPush, forKey: .skipPush)
        
        try container.encode(assignRoles, forKey: .assignRoles)
        
        try container.encode(cooldown, forKey: .cooldown)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(acceptInvite, forKey: .acceptInvite)
        
        try container.encode(data, forKey: .data)
        
        try container.encode(invites, forKey: .invites)
        
        try container.encode(rejectInvite, forKey: .rejectInvite)
    }
}
