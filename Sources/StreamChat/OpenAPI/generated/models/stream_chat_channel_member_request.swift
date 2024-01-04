//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMemberRequest: Codable, Hashable {
    public var banExpires: String?
    
    public var inviteRejectedAt: String?
    
    public var user: StreamChatUserObjectRequest?
    
    public var channelRole: String?
    
    public var createdAt: String?
    
    public var shadowBanned: Bool?
    
    public var status: String?
    
    public var updatedAt: String?
    
    public var userId: String?
    
    public var deletedAt: String?
    
    public var inviteAcceptedAt: String?
    
    public var isModerator: Bool?
    
    public var notificationsMuted: Bool?
    
    public var banned: Bool?
    
    public var invited: Bool?
    
    public var role: String?
    
    public init(banExpires: String?, inviteRejectedAt: String?, user: StreamChatUserObjectRequest?, channelRole: String?, createdAt: String?, shadowBanned: Bool?, status: String?, updatedAt: String?, userId: String?, deletedAt: String?, inviteAcceptedAt: String?, isModerator: Bool?, notificationsMuted: Bool?, banned: Bool?, invited: Bool?, role: String?) {
        self.banExpires = banExpires
        
        self.inviteRejectedAt = inviteRejectedAt
        
        self.user = user
        
        self.channelRole = channelRole
        
        self.createdAt = createdAt
        
        self.shadowBanned = shadowBanned
        
        self.status = status
        
        self.updatedAt = updatedAt
        
        self.userId = userId
        
        self.deletedAt = deletedAt
        
        self.inviteAcceptedAt = inviteAcceptedAt
        
        self.isModerator = isModerator
        
        self.notificationsMuted = notificationsMuted
        
        self.banned = banned
        
        self.invited = invited
        
        self.role = role
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case banExpires = "ban_expires"
        
        case inviteRejectedAt = "invite_rejected_at"
        
        case user
        
        case channelRole = "channel_role"
        
        case createdAt = "created_at"
        
        case shadowBanned = "shadow_banned"
        
        case status
        
        case updatedAt = "updated_at"
        
        case userId = "user_id"
        
        case deletedAt = "deleted_at"
        
        case inviteAcceptedAt = "invite_accepted_at"
        
        case isModerator = "is_moderator"
        
        case notificationsMuted = "notifications_muted"
        
        case banned
        
        case invited
        
        case role
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(inviteRejectedAt, forKey: .inviteRejectedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelRole, forKey: .channelRole)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(status, forKey: .status)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(inviteAcceptedAt, forKey: .inviteAcceptedAt)
        
        try container.encode(isModerator, forKey: .isModerator)
        
        try container.encode(notificationsMuted, forKey: .notificationsMuted)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(invited, forKey: .invited)
        
        try container.encode(role, forKey: .role)
    }
}
