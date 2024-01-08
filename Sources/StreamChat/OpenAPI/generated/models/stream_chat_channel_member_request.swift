//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMemberRequest: Codable, Hashable {
    public var inviteAcceptedAt: String?
    
    public var isModerator: Bool?
    
    public var shadowBanned: Bool?
    
    public var updatedAt: String?
    
    public var banned: Bool?
    
    public var inviteRejectedAt: String?
    
    public var notificationsMuted: Bool?
    
    public var user: StreamChatUserObjectRequest?
    
    public var channelRole: String?
    
    public var deletedAt: String?
    
    public var invited: Bool?
    
    public var role: String?
    
    public var banExpires: String?
    
    public var createdAt: String?
    
    public var status: String?
    
    public var userId: String?
    
    public init(inviteAcceptedAt: String?, isModerator: Bool?, shadowBanned: Bool?, updatedAt: String?, banned: Bool?, inviteRejectedAt: String?, notificationsMuted: Bool?, user: StreamChatUserObjectRequest?, channelRole: String?, deletedAt: String?, invited: Bool?, role: String?, banExpires: String?, createdAt: String?, status: String?, userId: String?) {
        self.inviteAcceptedAt = inviteAcceptedAt
        
        self.isModerator = isModerator
        
        self.shadowBanned = shadowBanned
        
        self.updatedAt = updatedAt
        
        self.banned = banned
        
        self.inviteRejectedAt = inviteRejectedAt
        
        self.notificationsMuted = notificationsMuted
        
        self.user = user
        
        self.channelRole = channelRole
        
        self.deletedAt = deletedAt
        
        self.invited = invited
        
        self.role = role
        
        self.banExpires = banExpires
        
        self.createdAt = createdAt
        
        self.status = status
        
        self.userId = userId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case inviteAcceptedAt = "invite_accepted_at"
        
        case isModerator = "is_moderator"
        
        case shadowBanned = "shadow_banned"
        
        case updatedAt = "updated_at"
        
        case banned
        
        case inviteRejectedAt = "invite_rejected_at"
        
        case notificationsMuted = "notifications_muted"
        
        case user
        
        case channelRole = "channel_role"
        
        case deletedAt = "deleted_at"
        
        case invited
        
        case role
        
        case banExpires = "ban_expires"
        
        case createdAt = "created_at"
        
        case status
        
        case userId = "user_id"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(inviteAcceptedAt, forKey: .inviteAcceptedAt)
        
        try container.encode(isModerator, forKey: .isModerator)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(inviteRejectedAt, forKey: .inviteRejectedAt)
        
        try container.encode(notificationsMuted, forKey: .notificationsMuted)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channelRole, forKey: .channelRole)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(invited, forKey: .invited)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(status, forKey: .status)
        
        try container.encode(userId, forKey: .userId)
    }
}
