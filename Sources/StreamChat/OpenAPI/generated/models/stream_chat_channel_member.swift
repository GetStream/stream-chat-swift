//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMember: Codable, Hashable {
    public var banned: Bool
    
    public var deletedAt: String?
    
    public var role: String?
    
    public var banExpires: String?
    
    public var createdAt: String
    
    public var inviteAcceptedAt: String?
    
    public var updatedAt: String
    
    public var user: StreamChatUserObject?
    
    public var userId: String?
    
    public var channelRole: String
    
    public var invited: Bool?
    
    public var isModerator: Bool?
    
    public var notificationsMuted: Bool
    
    public var shadowBanned: Bool
    
    public var status: String?
    
    public var inviteRejectedAt: String?
    
    public init(banned: Bool, deletedAt: String?, role: String?, banExpires: String?, createdAt: String, inviteAcceptedAt: String?, updatedAt: String, user: StreamChatUserObject?, userId: String?, channelRole: String, invited: Bool?, isModerator: Bool?, notificationsMuted: Bool, shadowBanned: Bool, status: String?, inviteRejectedAt: String?) {
        self.banned = banned
        
        self.deletedAt = deletedAt
        
        self.role = role
        
        self.banExpires = banExpires
        
        self.createdAt = createdAt
        
        self.inviteAcceptedAt = inviteAcceptedAt
        
        self.updatedAt = updatedAt
        
        self.user = user
        
        self.userId = userId
        
        self.channelRole = channelRole
        
        self.invited = invited
        
        self.isModerator = isModerator
        
        self.notificationsMuted = notificationsMuted
        
        self.shadowBanned = shadowBanned
        
        self.status = status
        
        self.inviteRejectedAt = inviteRejectedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banned
        
        case deletedAt = "deleted_at"
        
        case role
        
        case banExpires = "ban_expires"
        
        case createdAt = "created_at"
        
        case inviteAcceptedAt = "invite_accepted_at"
        
        case updatedAt = "updated_at"
        
        case user
        
        case userId = "user_id"
        
        case channelRole = "channel_role"
        
        case invited
        
        case isModerator = "is_moderator"
        
        case notificationsMuted = "notifications_muted"
        
        case shadowBanned = "shadow_banned"
        
        case status
        
        case inviteRejectedAt = "invite_rejected_at"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(inviteAcceptedAt, forKey: .inviteAcceptedAt)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(channelRole, forKey: .channelRole)
        
        try container.encode(invited, forKey: .invited)
        
        try container.encode(isModerator, forKey: .isModerator)
        
        try container.encode(notificationsMuted, forKey: .notificationsMuted)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(status, forKey: .status)
        
        try container.encode(inviteRejectedAt, forKey: .inviteRejectedAt)
    }
}
