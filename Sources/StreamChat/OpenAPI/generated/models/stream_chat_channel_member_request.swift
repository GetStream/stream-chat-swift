//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMemberRequest: Codable, Hashable {
    public var banExpires: String?
    
    public var banned: Bool?
    
    public var shadowBanned: Bool?
    
    public var userId: String?
    
    public var inviteAcceptedAt: String?
    
    public var notificationsMuted: Bool?
    
    public var role: String?
    
    public var status: String?
    
    public var updatedAt: String?
    
    public var user: StreamChatUserObjectRequest?
    
    public var channelRole: String?
    
    public var createdAt: String?
    
    public var deletedAt: String?
    
    public var inviteRejectedAt: String?
    
    public var invited: Bool?
    
    public var isModerator: Bool?
    
    public init(banExpires: String?, banned: Bool?, shadowBanned: Bool?, userId: String?, inviteAcceptedAt: String?, notificationsMuted: Bool?, role: String?, status: String?, updatedAt: String?, user: StreamChatUserObjectRequest?, channelRole: String?, createdAt: String?, deletedAt: String?, inviteRejectedAt: String?, invited: Bool?, isModerator: Bool?) {
        self.banExpires = banExpires
        
        self.banned = banned
        
        self.shadowBanned = shadowBanned
        
        self.userId = userId
        
        self.inviteAcceptedAt = inviteAcceptedAt
        
        self.notificationsMuted = notificationsMuted
        
        self.role = role
        
        self.status = status
        
        self.updatedAt = updatedAt
        
        self.user = user
        
        self.channelRole = channelRole
        
        self.createdAt = createdAt
        
        self.deletedAt = deletedAt
        
        self.inviteRejectedAt = inviteRejectedAt
        
        self.invited = invited
        
        self.isModerator = isModerator
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banExpires = "ban_expires"
        
        case banned
        
        case shadowBanned = "shadow_banned"
        
        case userId = "user_id"
        
        case inviteAcceptedAt = "invite_accepted_at"
        
        case notificationsMuted = "notifications_muted"
        
        case role
        
        case status
        
        case updatedAt = "updated_at"
        
        case user
        
        case channelRole = "channel_role"
        
        case createdAt = "created_at"
        
        case deletedAt = "deleted_at"
        
        case inviteRejectedAt = "invite_rejected_at"
        
        case invited
        
        case isModerator = "is_moderator"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(inviteAcceptedAt, forKey: .inviteAcceptedAt)
        
        try container.encode(notificationsMuted, forKey: .notificationsMuted)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(status, forKey: .status)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelRole, forKey: .channelRole)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(inviteRejectedAt, forKey: .inviteRejectedAt)
        
        try container.encode(invited, forKey: .invited)
        
        try container.encode(isModerator, forKey: .isModerator)
    }
}
