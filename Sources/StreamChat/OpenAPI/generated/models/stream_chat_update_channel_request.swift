//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateChannelRequest: Codable, Hashable {
    public var rejectInvite: Bool?
    
    public var skipPush: Bool?
    
    public var acceptInvite: Bool?
    
    public var addModerators: [String]
    
    public var invites: [StreamChatChannelMemberRequest?]?
    
    public var demoteModerators: [String]
    
    public var message: StreamChatMessageRequest?
    
    public var removeMembers: [String]
    
    public var data: StreamChatChannelRequest?
    
    public var hideHistory: Bool?
    
    public var addMembers: [StreamChatChannelMemberRequest?]?
    
    public var assignRoles: [StreamChatChannelMemberRequest?]?
    
    public var cooldown: Int?
    
    public init(rejectInvite: Bool?, skipPush: Bool?, acceptInvite: Bool?, addModerators: [String], invites: [StreamChatChannelMemberRequest?]?, demoteModerators: [String], message: StreamChatMessageRequest?, removeMembers: [String], data: StreamChatChannelRequest?, hideHistory: Bool?, addMembers: [StreamChatChannelMemberRequest?]?, assignRoles: [StreamChatChannelMemberRequest?]?, cooldown: Int?) {
        self.rejectInvite = rejectInvite
        
        self.skipPush = skipPush
        
        self.acceptInvite = acceptInvite
        
        self.addModerators = addModerators
        
        self.invites = invites
        
        self.demoteModerators = demoteModerators
        
        self.message = message
        
        self.removeMembers = removeMembers
        
        self.data = data
        
        self.hideHistory = hideHistory
        
        self.addMembers = addMembers
        
        self.assignRoles = assignRoles
        
        self.cooldown = cooldown
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case rejectInvite = "reject_invite"
        
        case skipPush = "skip_push"
        
        case acceptInvite = "accept_invite"
        
        case addModerators = "add_moderators"
        
        case invites
        
        case demoteModerators = "demote_moderators"
        
        case message
        
        case removeMembers = "remove_members"
        
        case data
        
        case hideHistory = "hide_history"
        
        case addMembers = "add_members"
        
        case assignRoles = "assign_roles"
        
        case cooldown
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(rejectInvite, forKey: .rejectInvite)
        
        try container.encode(skipPush, forKey: .skipPush)
        
        try container.encode(acceptInvite, forKey: .acceptInvite)
        
        try container.encode(addModerators, forKey: .addModerators)
        
        try container.encode(invites, forKey: .invites)
        
        try container.encode(demoteModerators, forKey: .demoteModerators)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(removeMembers, forKey: .removeMembers)
        
        try container.encode(data, forKey: .data)
        
        try container.encode(hideHistory, forKey: .hideHistory)
        
        try container.encode(addMembers, forKey: .addMembers)
        
        try container.encode(assignRoles, forKey: .assignRoles)
        
        try container.encode(cooldown, forKey: .cooldown)
    }
}
