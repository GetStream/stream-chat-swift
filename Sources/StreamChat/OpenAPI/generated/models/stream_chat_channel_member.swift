//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMember: Codable, Hashable {
    public var banExpires: String?
    
    public var notificationsMuted: Bool
    
    public var status: String?
    
    public var user: StreamChatUserObject?
    
    public var userId: String?
    
    public var channelRole: String
    
    public var inviteRejectedAt: String?
    
    public var role: String?
    
    public var updatedAt: String
    
    public var shadowBanned: Bool
    
    public var createdAt: String
    
    public var deletedAt: String?
    
    public var inviteAcceptedAt: String?
    
    public var invited: Bool?
    
    public var isModerator: Bool?
    
    public var banned: Bool
    
    public init(banExpires: String?, notificationsMuted: Bool, status: String?, user: StreamChatUserObject?, userId: String?, channelRole: String, inviteRejectedAt: String?, role: String?, updatedAt: String, shadowBanned: Bool, createdAt: String, deletedAt: String?, inviteAcceptedAt: String?, invited: Bool?, isModerator: Bool?, banned: Bool) {
        self.banExpires = banExpires
        
        self.notificationsMuted = notificationsMuted
        
        self.status = status
        
        self.user = user
        
        self.userId = userId
        
        self.channelRole = channelRole
        
        self.inviteRejectedAt = inviteRejectedAt
        
        self.role = role
        
        self.updatedAt = updatedAt
        
        self.shadowBanned = shadowBanned
        
        self.createdAt = createdAt
        
        self.deletedAt = deletedAt
        
        self.inviteAcceptedAt = inviteAcceptedAt
        
        self.invited = invited
        
        self.isModerator = isModerator
        
        self.banned = banned
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banExpires = "ban_expires"
        
        case notificationsMuted = "notifications_muted"
        
        case status
        
        case user
        
        case userId = "user_id"
        
        case channelRole = "channel_role"
        
        case inviteRejectedAt = "invite_rejected_at"
        
        case role
        
        case updatedAt = "updated_at"
        
        case shadowBanned = "shadow_banned"
        
        case createdAt = "created_at"
        
        case deletedAt = "deleted_at"
        
        case inviteAcceptedAt = "invite_accepted_at"
        
        case invited
        
        case isModerator = "is_moderator"
        
        case banned
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(notificationsMuted, forKey: .notificationsMuted)
        
        try container.encode(status, forKey: .status)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(channelRole, forKey: .channelRole)
        
        try container.encode(inviteRejectedAt, forKey: .inviteRejectedAt)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(inviteAcceptedAt, forKey: .inviteAcceptedAt)
        
        try container.encode(invited, forKey: .invited)
        
        try container.encode(isModerator, forKey: .isModerator)
        
        try container.encode(banned, forKey: .banned)
    }
}
