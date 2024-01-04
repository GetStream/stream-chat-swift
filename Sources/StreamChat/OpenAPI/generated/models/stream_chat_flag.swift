//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlag: Codable, Hashable {
    public var reason: String?
    
    public var targetMessageId: String?
    
    public var updatedAt: String
    
    public var createdAt: String
    
    public var rejectedAt: String?
    
    public var targetUser: StreamChatUserObject?
    
    public var details: StreamChatFlagDetails?
    
    public var reviewedAt: String?
    
    public var user: StreamChatUserObject?
    
    public var approvedAt: String?
    
    public var createdByAutomod: Bool
    
    public var custom: [String: RawJSON]?
    
    public var targetMessage: StreamChatMessage?
    
    public init(reason: String?, targetMessageId: String?, updatedAt: String, createdAt: String, rejectedAt: String?, targetUser: StreamChatUserObject?, details: StreamChatFlagDetails?, reviewedAt: String?, user: StreamChatUserObject?, approvedAt: String?, createdByAutomod: Bool, custom: [String: RawJSON]?, targetMessage: StreamChatMessage?) {
        self.reason = reason
        
        self.targetMessageId = targetMessageId
        
        self.updatedAt = updatedAt
        
        self.createdAt = createdAt
        
        self.rejectedAt = rejectedAt
        
        self.targetUser = targetUser
        
        self.details = details
        
        self.reviewedAt = reviewedAt
        
        self.user = user
        
        self.approvedAt = approvedAt
        
        self.createdByAutomod = createdByAutomod
        
        self.custom = custom
        
        self.targetMessage = targetMessage
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reason
        
        case targetMessageId = "target_message_id"
        
        case updatedAt = "updated_at"
        
        case createdAt = "created_at"
        
        case rejectedAt = "rejected_at"
        
        case targetUser = "target_user"
        
        case details
        
        case reviewedAt = "reviewed_at"
        
        case user
        
        case approvedAt = "approved_at"
        
        case createdByAutomod = "created_by_automod"
        
        case custom
        
        case targetMessage = "target_message"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(targetMessageId, forKey: .targetMessageId)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(rejectedAt, forKey: .rejectedAt)
        
        try container.encode(targetUser, forKey: .targetUser)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(approvedAt, forKey: .approvedAt)
        
        try container.encode(createdByAutomod, forKey: .createdByAutomod)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(targetMessage, forKey: .targetMessage)
    }
}
