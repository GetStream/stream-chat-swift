//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMember: Codable, Hashable {
    public var deletedAt: String?
    
    public var inviteRejectedAt: String?
    
    public var notificationsMuted: Bool
    
    public var banExpires: String?
    
    public var banned: Bool
    
    public var createdAt: String
    
    public var channelRole: String
    
    public var status: String?
    
    public var role: String?
    
    public var shadowBanned: Bool
    
    public var user: StreamChatUserObject?
    
    public var updatedAt: String
    
    public var userId: String?
    
    public var inviteAcceptedAt: String?
    
    public var invited: Bool?
    
    public var isModerator: Bool?
    
    public init(deletedAt: String?, inviteRejectedAt: String?, notificationsMuted: Bool, banExpires: String?, banned: Bool, createdAt: String, channelRole: String, status: String?, role: String?, shadowBanned: Bool, user: StreamChatUserObject?, updatedAt: String, userId: String?, inviteAcceptedAt: String?, invited: Bool?, isModerator: Bool?) {
        self.deletedAt = deletedAt
        
        self.inviteRejectedAt = inviteRejectedAt
        
        self.notificationsMuted = notificationsMuted
        
        self.banExpires = banExpires
        
        self.banned = banned
        
        self.createdAt = createdAt
        
        self.channelRole = channelRole
        
        self.status = status
        
        self.role = role
        
        self.shadowBanned = shadowBanned
        
        self.user = user
        
        self.updatedAt = updatedAt
        
        self.userId = userId
        
        self.inviteAcceptedAt = inviteAcceptedAt
        
        self.invited = invited
        
        self.isModerator = isModerator
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case deletedAt = "deleted_at"
        
        case inviteRejectedAt = "invite_rejected_at"
        
        case notificationsMuted = "notifications_muted"
        
        case banExpires = "ban_expires"
        
        case banned
        
        case createdAt = "created_at"
        
        case channelRole = "channel_role"
        
        case status
        
        case role
        
        case shadowBanned = "shadow_banned"
        
        case user
        
        case updatedAt = "updated_at"
        
        case userId = "user_id"
        
        case inviteAcceptedAt = "invite_accepted_at"
        
        case invited
        
        case isModerator = "is_moderator"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(inviteRejectedAt, forKey: .inviteRejectedAt)
        
        try container.encode(notificationsMuted, forKey: .notificationsMuted)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(channelRole, forKey: .channelRole)
        
        try container.encode(status, forKey: .status)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(inviteAcceptedAt, forKey: .inviteAcceptedAt)
        
        try container.encode(invited, forKey: .invited)
        
        try container.encode(isModerator, forKey: .isModerator)
    }
}
