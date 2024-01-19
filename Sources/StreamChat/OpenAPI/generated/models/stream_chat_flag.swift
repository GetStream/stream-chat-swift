//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlag: Codable, Hashable {
    public var createdAt: Date
    
    public var rejectedAt: Date?
    
    public var targetMessageId: String?
    
    public var approvedAt: Date?
    
    public var createdByAutomod: Bool
    
    public var targetMessage: StreamChatMessage?
    
    public var targetUser: StreamChatUserObject?
    
    public var updatedAt: Date
    
    public var user: StreamChatUserObject?
    
    public var custom: [String: RawJSON]?
    
    public var details: StreamChatFlagDetails?
    
    public var reason: String?
    
    public var reviewedAt: Date?
    
    public init(createdAt: Date, rejectedAt: Date?, targetMessageId: String?, approvedAt: Date?, createdByAutomod: Bool, targetMessage: StreamChatMessage?, targetUser: StreamChatUserObject?, updatedAt: Date, user: StreamChatUserObject?, custom: [String: RawJSON]?, details: StreamChatFlagDetails?, reason: String?, reviewedAt: Date?) {
        self.createdAt = createdAt
        
        self.rejectedAt = rejectedAt
        
        self.targetMessageId = targetMessageId
        
        self.approvedAt = approvedAt
        
        self.createdByAutomod = createdByAutomod
        
        self.targetMessage = targetMessage
        
        self.targetUser = targetUser
        
        self.updatedAt = updatedAt
        
        self.user = user
        
        self.custom = custom
        
        self.details = details
        
        self.reason = reason
        
        self.reviewedAt = reviewedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case rejectedAt = "rejected_at"
        
        case targetMessageId = "target_message_id"
        
        case approvedAt = "approved_at"
        
        case createdByAutomod = "created_by_automod"
        
        case targetMessage = "target_message"
        
        case targetUser = "target_user"
        
        case updatedAt = "updated_at"
        
        case user
        
        case custom
        
        case details
        
        case reason
        
        case reviewedAt = "reviewed_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(rejectedAt, forKey: .rejectedAt)
        
        try container.encode(targetMessageId, forKey: .targetMessageId)
        
        try container.encode(approvedAt, forKey: .approvedAt)
        
        try container.encode(createdByAutomod, forKey: .createdByAutomod)
        
        try container.encode(targetMessage, forKey: .targetMessage)
        
        try container.encode(targetUser, forKey: .targetUser)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
    }
}
