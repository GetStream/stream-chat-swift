//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMemberRequest: Codable, Hashable {
    public var isModerator: Bool?
    
    public var status: String?
    
    public var banExpires: Date?
    
    public var channelRole: String?
    
    public var inviteAcceptedAt: Date?
    
    public var invited: Bool?
    
    public var role: String?
    
    public var shadowBanned: Bool?
    
    public var updatedAt: Date?
    
    public var user: StreamChatUserObjectRequest?
    
    public var createdAt: Date?
    
    public var deletedAt: Date?
    
    public var banned: Bool?
    
    public var userId: String?
    
    public var inviteRejectedAt: Date?
    
    public var notificationsMuted: Bool?
    
    public init(isModerator: Bool?, status: String?, banExpires: Date?, channelRole: String?, inviteAcceptedAt: Date?, invited: Bool?, role: String?, shadowBanned: Bool?, updatedAt: Date?, user: StreamChatUserObjectRequest?, createdAt: Date?, deletedAt: Date?, banned: Bool?, userId: String?, inviteRejectedAt: Date?, notificationsMuted: Bool?) {
        self.isModerator = isModerator
        
        self.status = status
        
        self.banExpires = banExpires
        
        self.channelRole = channelRole
        
        self.inviteAcceptedAt = inviteAcceptedAt
        
        self.invited = invited
        
        self.role = role
        
        self.shadowBanned = shadowBanned
        
        self.updatedAt = updatedAt
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.deletedAt = deletedAt
        
        self.banned = banned
        
        self.userId = userId
        
        self.inviteRejectedAt = inviteRejectedAt
        
        self.notificationsMuted = notificationsMuted
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case isModerator = "is_moderator"
        
        case status
        
        case banExpires = "ban_expires"
        
        case channelRole = "channel_role"
        
        case inviteAcceptedAt = "invite_accepted_at"
        
        case invited
        
        case role
        
        case shadowBanned = "shadow_banned"
        
        case updatedAt = "updated_at"
        
        case user
        
        case createdAt = "created_at"
        
        case deletedAt = "deleted_at"
        
        case banned
        
        case userId = "user_id"
        
        case inviteRejectedAt = "invite_rejected_at"
        
        case notificationsMuted = "notifications_muted"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(isModerator, forKey: .isModerator)
        
        try container.encode(status, forKey: .status)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(channelRole, forKey: .channelRole)
        
        try container.encode(inviteAcceptedAt, forKey: .inviteAcceptedAt)
        
        try container.encode(invited, forKey: .invited)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(inviteRejectedAt, forKey: .inviteRejectedAt)
        
        try container.encode(notificationsMuted, forKey: .notificationsMuted)
    }
}
