//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlag: Codable, Hashable {
    public var rejectedAt: String?
    
    public var targetMessageId: String?
    
    public var updatedAt: String
    
    public var approvedAt: String?
    
    public var createdByAutomod: Bool
    
    public var reason: String?
    
    public var reviewedAt: String?
    
    public var user: StreamChatUserObject?
    
    public var createdAt: String
    
    public var targetMessage: StreamChatMessage?
    
    public var custom: [String: RawJSON]?
    
    public var details: StreamChatFlagDetails?
    
    public var targetUser: StreamChatUserObject?
    
    public init(rejectedAt: String?, targetMessageId: String?, updatedAt: String, approvedAt: String?, createdByAutomod: Bool, reason: String?, reviewedAt: String?, user: StreamChatUserObject?, createdAt: String, targetMessage: StreamChatMessage?, custom: [String: RawJSON]?, details: StreamChatFlagDetails?, targetUser: StreamChatUserObject?) {
        self.rejectedAt = rejectedAt
        
        self.targetMessageId = targetMessageId
        
        self.updatedAt = updatedAt
        
        self.approvedAt = approvedAt
        
        self.createdByAutomod = createdByAutomod
        
        self.reason = reason
        
        self.reviewedAt = reviewedAt
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.targetMessage = targetMessage
        
        self.custom = custom
        
        self.details = details
        
        self.targetUser = targetUser
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case rejectedAt = "rejected_at"
        
        case targetMessageId = "target_message_id"
        
        case updatedAt = "updated_at"
        
        case approvedAt = "approved_at"
        
        case createdByAutomod = "created_by_automod"
        
        case reason
        
        case reviewedAt = "reviewed_at"
        
        case user
        
        case createdAt = "created_at"
        
        case targetMessage = "target_message"
        
        case custom
        
        case details
        
        case targetUser = "target_user"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(rejectedAt, forKey: .rejectedAt)
        
        try container.encode(targetMessageId, forKey: .targetMessageId)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(approvedAt, forKey: .approvedAt)
        
        try container.encode(createdByAutomod, forKey: .createdByAutomod)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(targetMessage, forKey: .targetMessage)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(targetUser, forKey: .targetUser)
    }
}
