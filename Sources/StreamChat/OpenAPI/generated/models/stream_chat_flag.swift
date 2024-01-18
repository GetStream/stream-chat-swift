//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlag: Codable, Hashable {
    public var rejectedAt: Date?
    
    public var reviewedAt: Date?
    
    public var targetMessage: StreamChatMessage?
    
    public var updatedAt: Date
    
    public var user: StreamChatUserObject?
    
    public var custom: [String: RawJSON]?
    
    public var reason: String?
    
    public var createdByAutomod: Bool
    
    public var details: StreamChatFlagDetails?
    
    public var targetMessageId: String?
    
    public var targetUser: StreamChatUserObject?
    
    public var approvedAt: Date?
    
    public var createdAt: Date
    
    public init(rejectedAt: Date?, reviewedAt: Date?, targetMessage: StreamChatMessage?, updatedAt: Date, user: StreamChatUserObject?, custom: [String: RawJSON]?, reason: String?, createdByAutomod: Bool, details: StreamChatFlagDetails?, targetMessageId: String?, targetUser: StreamChatUserObject?, approvedAt: Date?, createdAt: Date) {
        self.rejectedAt = rejectedAt
        
        self.reviewedAt = reviewedAt
        
        self.targetMessage = targetMessage
        
        self.updatedAt = updatedAt
        
        self.user = user
        
        self.custom = custom
        
        self.reason = reason
        
        self.createdByAutomod = createdByAutomod
        
        self.details = details
        
        self.targetMessageId = targetMessageId
        
        self.targetUser = targetUser
        
        self.approvedAt = approvedAt
        
        self.createdAt = createdAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case rejectedAt = "rejected_at"
        
        case reviewedAt = "reviewed_at"
        
        case targetMessage = "target_message"
        
        case updatedAt = "updated_at"
        
        case user
        
        case custom
        
        case reason
        
        case createdByAutomod = "created_by_automod"
        
        case details
        
        case targetMessageId = "target_message_id"
        
        case targetUser = "target_user"
        
        case approvedAt = "approved_at"
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(rejectedAt, forKey: .rejectedAt)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
        
        try container.encode(targetMessage, forKey: .targetMessage)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(createdByAutomod, forKey: .createdByAutomod)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(targetMessageId, forKey: .targetMessageId)
        
        try container.encode(targetUser, forKey: .targetUser)
        
        try container.encode(approvedAt, forKey: .approvedAt)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}
