//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlag: Codable, Hashable {
    public var createdAt: Date
    
    public var createdByAutomod: Bool
    
    public var updatedAt: Date
    
    public var approvedAt: Date? = nil
    
    public var reason: String? = nil
    
    public var rejectedAt: Date? = nil
    
    public var reviewedAt: Date? = nil
    
    public var targetMessageId: String? = nil
    
    public var custom: [String: RawJSON]? = nil
    
    public var details: StreamChatFlagDetails? = nil
    
    public var targetMessage: StreamChatMessage? = nil
    
    public var targetUser: StreamChatUserObject? = nil
    
    public var user: StreamChatUserObject? = nil
    
    public init(createdAt: Date, createdByAutomod: Bool, updatedAt: Date, approvedAt: Date? = nil, reason: String? = nil, rejectedAt: Date? = nil, reviewedAt: Date? = nil, targetMessageId: String? = nil, custom: [String: RawJSON]? = nil, details: StreamChatFlagDetails? = nil, targetMessage: StreamChatMessage? = nil, targetUser: StreamChatUserObject? = nil, user: StreamChatUserObject? = nil) {
        self.createdAt = createdAt
        
        self.createdByAutomod = createdByAutomod
        
        self.updatedAt = updatedAt
        
        self.approvedAt = approvedAt
        
        self.reason = reason
        
        self.rejectedAt = rejectedAt
        
        self.reviewedAt = reviewedAt
        
        self.targetMessageId = targetMessageId
        
        self.custom = custom
        
        self.details = details
        
        self.targetMessage = targetMessage
        
        self.targetUser = targetUser
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case createdByAutomod = "created_by_automod"
        
        case updatedAt = "updated_at"
        
        case approvedAt = "approved_at"
        
        case reason
        
        case rejectedAt = "rejected_at"
        
        case reviewedAt = "reviewed_at"
        
        case targetMessageId = "target_message_id"
        
        case custom
        
        case details
        
        case targetMessage = "target_message"
        
        case targetUser = "target_user"
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(createdByAutomod, forKey: .createdByAutomod)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(approvedAt, forKey: .approvedAt)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(rejectedAt, forKey: .rejectedAt)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
        
        try container.encode(targetMessageId, forKey: .targetMessageId)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(targetMessage, forKey: .targetMessage)
        
        try container.encode(targetUser, forKey: .targetUser)
        
        try container.encode(user, forKey: .user)
    }
}
