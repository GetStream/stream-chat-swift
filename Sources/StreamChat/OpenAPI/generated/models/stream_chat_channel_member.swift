//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMember: Codable, Hashable {
    public var shadowBanned: Bool
    
    public var userId: String?
    
    public var invited: Bool?
    
    public var isModerator: Bool?
    
    public var notificationsMuted: Bool
    
    public var role: String?
    
    public var updatedAt: Date
    
    public var inviteRejectedAt: Date?
    
    public var inviteAcceptedAt: Date?
    
    public var createdAt: Date
    
    public var banned: Bool
    
    public var channelRole: String
    
    public var deletedAt: Date?
    
    public var status: String?
    
    public var user: StreamChatUserObject?
    
    public var banExpires: Date?
    
    public init(shadowBanned: Bool, userId: String?, invited: Bool?, isModerator: Bool?, notificationsMuted: Bool, role: String?, updatedAt: Date, inviteRejectedAt: Date?, inviteAcceptedAt: Date?, createdAt: Date, banned: Bool, channelRole: String, deletedAt: Date?, status: String?, user: StreamChatUserObject?, banExpires: Date?) {
        self.shadowBanned = shadowBanned
        
        self.userId = userId
        
        self.invited = invited
        
        self.isModerator = isModerator
        
        self.notificationsMuted = notificationsMuted
        
        self.role = role
        
        self.updatedAt = updatedAt
        
        self.inviteRejectedAt = inviteRejectedAt
        
        self.inviteAcceptedAt = inviteAcceptedAt
        
        self.createdAt = createdAt
        
        self.banned = banned
        
        self.channelRole = channelRole
        
        self.deletedAt = deletedAt
        
        self.status = status
        
        self.user = user
        
        self.banExpires = banExpires
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case shadowBanned = "shadow_banned"
        
        case userId = "user_id"
        
        case invited
        
        case isModerator = "is_moderator"
        
        case notificationsMuted = "notifications_muted"
        
        case role
        
        case updatedAt = "updated_at"
        
        case inviteRejectedAt = "invite_rejected_at"
        
        case inviteAcceptedAt = "invite_accepted_at"
        
        case createdAt = "created_at"
        
        case banned
        
        case channelRole = "channel_role"
        
        case deletedAt = "deleted_at"
        
        case status
        
        case user
        
        case banExpires = "ban_expires"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(invited, forKey: .invited)
        
        try container.encode(isModerator, forKey: .isModerator)
        
        try container.encode(notificationsMuted, forKey: .notificationsMuted)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(inviteRejectedAt, forKey: .inviteRejectedAt)
        
        try container.encode(inviteAcceptedAt, forKey: .inviteAcceptedAt)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(channelRole, forKey: .channelRole)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(status, forKey: .status)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(banExpires, forKey: .banExpires)
    }
}
