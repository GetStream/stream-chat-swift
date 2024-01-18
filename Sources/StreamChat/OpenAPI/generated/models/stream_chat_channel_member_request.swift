//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMemberRequest: Codable, Hashable {
    public var channelRole: String?
    
    public var shadowBanned: Bool?
    
    public var createdAt: Date?
    
    public var deletedAt: Date?
    
    public var isModerator: Bool?
    
    public var notificationsMuted: Bool?
    
    public var user: StreamChatUserObjectRequest?
    
    public var banExpires: Date?
    
    public var banned: Bool?
    
    public var invited: Bool?
    
    public var updatedAt: Date?
    
    public var userId: String?
    
    public var inviteAcceptedAt: Date?
    
    public var inviteRejectedAt: Date?
    
    public var role: String?
    
    public var status: String?
    
    public init(channelRole: String?, shadowBanned: Bool?, createdAt: Date?, deletedAt: Date?, isModerator: Bool?, notificationsMuted: Bool?, user: StreamChatUserObjectRequest?, banExpires: Date?, banned: Bool?, invited: Bool?, updatedAt: Date?, userId: String?, inviteAcceptedAt: Date?, inviteRejectedAt: Date?, role: String?, status: String?) {
        self.channelRole = channelRole
        
        self.shadowBanned = shadowBanned
        
        self.createdAt = createdAt
        
        self.deletedAt = deletedAt
        
        self.isModerator = isModerator
        
        self.notificationsMuted = notificationsMuted
        
        self.user = user
        
        self.banExpires = banExpires
        
        self.banned = banned
        
        self.invited = invited
        
        self.updatedAt = updatedAt
        
        self.userId = userId
        
        self.inviteAcceptedAt = inviteAcceptedAt
        
        self.inviteRejectedAt = inviteRejectedAt
        
        self.role = role
        
        self.status = status
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelRole = "channel_role"
        
        case shadowBanned = "shadow_banned"
        
        case createdAt = "created_at"
        
        case deletedAt = "deleted_at"
        
        case isModerator = "is_moderator"
        
        case notificationsMuted = "notifications_muted"
        
        case user
        
        case banExpires = "ban_expires"
        
        case banned
        
        case invited
        
        case updatedAt = "updated_at"
        
        case userId = "user_id"
        
        case inviteAcceptedAt = "invite_accepted_at"
        
        case inviteRejectedAt = "invite_rejected_at"
        
        case role
        
        case status
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelRole, forKey: .channelRole)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(isModerator, forKey: .isModerator)
        
        try container.encode(notificationsMuted, forKey: .notificationsMuted)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(invited, forKey: .invited)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(inviteAcceptedAt, forKey: .inviteAcceptedAt)
        
        try container.encode(inviteRejectedAt, forKey: .inviteRejectedAt)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(status, forKey: .status)
    }
}
