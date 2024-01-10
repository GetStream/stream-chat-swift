//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlag: Codable, Hashable {
    public var reason: String?
    
    public var updatedAt: String
    
    public var createdAt: String
    
    public var targetUser: StreamChatUserObject?
    
    public var reviewedAt: String?
    
    public var custom: [String: RawJSON]?
    
    public var rejectedAt: String?
    
    public var targetMessageId: String?
    
    public var user: StreamChatUserObject?
    
    public var approvedAt: String?
    
    public var details: StreamChatFlagDetails?
    
    public var targetMessage: StreamChatMessage?
    
    public var createdByAutomod: Bool
    
    public init(reason: String?, updatedAt: String, createdAt: String, targetUser: StreamChatUserObject?, reviewedAt: String?, custom: [String: RawJSON]?, rejectedAt: String?, targetMessageId: String?, user: StreamChatUserObject?, approvedAt: String?, details: StreamChatFlagDetails?, targetMessage: StreamChatMessage?, createdByAutomod: Bool) {
        self.reason = reason
        
        self.updatedAt = updatedAt
        
        self.createdAt = createdAt
        
        self.targetUser = targetUser
        
        self.reviewedAt = reviewedAt
        
        self.custom = custom
        
        self.rejectedAt = rejectedAt
        
        self.targetMessageId = targetMessageId
        
        self.user = user
        
        self.approvedAt = approvedAt
        
        self.details = details
        
        self.targetMessage = targetMessage
        
        self.createdByAutomod = createdByAutomod
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reason
        
        case updatedAt = "updated_at"
        
        case createdAt = "created_at"
        
        case targetUser = "target_user"
        
        case reviewedAt = "reviewed_at"
        
        case custom
        
        case rejectedAt = "rejected_at"
        
        case targetMessageId = "target_message_id"
        
        case user
        
        case approvedAt = "approved_at"
        
        case details
        
        case targetMessage = "target_message"
        
        case createdByAutomod = "created_by_automod"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(targetUser, forKey: .targetUser)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(rejectedAt, forKey: .rejectedAt)
        
        try container.encode(targetMessageId, forKey: .targetMessageId)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(approvedAt, forKey: .approvedAt)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(targetMessage, forKey: .targetMessage)
        
        try container.encode(createdByAutomod, forKey: .createdByAutomod)
    }
}
