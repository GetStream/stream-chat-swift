//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageFlag: Codable, Hashable {
    public var approvedAt: String?
    
    public var custom: [String: RawJSON]?
    
    public var moderationResult: StreamChatMessageModerationResult?
    
    public var reviewedAt: String?
    
    public var reviewedBy: StreamChatUserObject?
    
    public var user: StreamChatUserObject?
    
    public var details: StreamChatFlagDetails?
    
    public var moderationFeedback: StreamChatFlagFeedback?
    
    public var reason: String?
    
    public var rejectedAt: String?
    
    public var createdAt: String
    
    public var createdByAutomod: Bool
    
    public var message: StreamChatMessage?
    
    public var updatedAt: String
    
    public init(approvedAt: String?, custom: [String: RawJSON]?, moderationResult: StreamChatMessageModerationResult?, reviewedAt: String?, reviewedBy: StreamChatUserObject?, user: StreamChatUserObject?, details: StreamChatFlagDetails?, moderationFeedback: StreamChatFlagFeedback?, reason: String?, rejectedAt: String?, createdAt: String, createdByAutomod: Bool, message: StreamChatMessage?, updatedAt: String) {
        self.approvedAt = approvedAt
        
        self.custom = custom
        
        self.moderationResult = moderationResult
        
        self.reviewedAt = reviewedAt
        
        self.reviewedBy = reviewedBy
        
        self.user = user
        
        self.details = details
        
        self.moderationFeedback = moderationFeedback
        
        self.reason = reason
        
        self.rejectedAt = rejectedAt
        
        self.createdAt = createdAt
        
        self.createdByAutomod = createdByAutomod
        
        self.message = message
        
        self.updatedAt = updatedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case approvedAt = "approved_at"
        
        case custom
        
        case moderationResult = "moderation_result"
        
        case reviewedAt = "reviewed_at"
        
        case reviewedBy = "reviewed_by"
        
        case user
        
        case details
        
        case moderationFeedback = "moderation_feedback"
        
        case reason
        
        case rejectedAt = "rejected_at"
        
        case createdAt = "created_at"
        
        case createdByAutomod = "created_by_automod"
        
        case message
        
        case updatedAt = "updated_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(approvedAt, forKey: .approvedAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(moderationResult, forKey: .moderationResult)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
        
        try container.encode(reviewedBy, forKey: .reviewedBy)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(moderationFeedback, forKey: .moderationFeedback)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(rejectedAt, forKey: .rejectedAt)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(createdByAutomod, forKey: .createdByAutomod)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
