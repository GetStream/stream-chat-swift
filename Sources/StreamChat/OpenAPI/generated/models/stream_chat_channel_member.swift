//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelMember: Codable, Hashable {
    public var isModerator: Bool?
    
    public var updatedAt: Date
    
    public var userId: String?
    
    public var banExpires: Date?
    
    public var createdAt: Date
    
    public var deletedAt: Date?
    
    public var inviteAcceptedAt: Date?
    
    public var inviteRejectedAt: Date?
    
    public var shadowBanned: Bool
    
    public var status: String?
    
    public var user: StreamChatUserObject?
    
    public var invited: Bool?
    
    public var notificationsMuted: Bool
    
    public var role: String?
    
    public var banned: Bool
    
    public var channelRole: String
    
    public init(isModerator: Bool?, updatedAt: Date, userId: String?, banExpires: Date?, createdAt: Date, deletedAt: Date?, inviteAcceptedAt: Date?, inviteRejectedAt: Date?, shadowBanned: Bool, status: String?, user: StreamChatUserObject?, invited: Bool?, notificationsMuted: Bool, role: String?, banned: Bool, channelRole: String) {
        self.isModerator = isModerator
        
        self.updatedAt = updatedAt
        
        self.userId = userId
        
        self.banExpires = banExpires
        
        self.createdAt = createdAt
        
        self.deletedAt = deletedAt
        
        self.inviteAcceptedAt = inviteAcceptedAt
        
        self.inviteRejectedAt = inviteRejectedAt
        
        self.shadowBanned = shadowBanned
        
        self.status = status
        
        self.user = user
        
        self.invited = invited
        
        self.notificationsMuted = notificationsMuted
        
        self.role = role
        
        self.banned = banned
        
        self.channelRole = channelRole
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case isModerator = "is_moderator"
        
        case updatedAt = "updated_at"
        
        case userId = "user_id"
        
        case banExpires = "ban_expires"
        
        case createdAt = "created_at"
        
        case deletedAt = "deleted_at"
        
        case inviteAcceptedAt = "invite_accepted_at"
        
        case inviteRejectedAt = "invite_rejected_at"
        
        case shadowBanned = "shadow_banned"
        
        case status
        
        case user
        
        case invited
        
        case notificationsMuted = "notifications_muted"
        
        case role
        
        case banned
        
        case channelRole = "channel_role"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(isModerator, forKey: .isModerator)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(banExpires, forKey: .banExpires)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(deletedAt, forKey: .deletedAt)
        
        try container.encode(inviteAcceptedAt, forKey: .inviteAcceptedAt)
        
        try container.encode(inviteRejectedAt, forKey: .inviteRejectedAt)
        
        try container.encode(shadowBanned, forKey: .shadowBanned)
        
        try container.encode(status, forKey: .status)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(invited, forKey: .invited)
        
        try container.encode(notificationsMuted, forKey: .notificationsMuted)
        
        try container.encode(role, forKey: .role)
        
        try container.encode(banned, forKey: .banned)
        
        try container.encode(channelRole, forKey: .channelRole)
    }
}
