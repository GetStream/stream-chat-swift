//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageFlag: Codable, Hashable {
    public var details: StreamChatFlagDetails?
    
    public var moderationFeedback: StreamChatFlagFeedback?
    
    public var user: StreamChatUserObject?
    
    public var createdByAutomod: Bool
    
    public var message: StreamChatMessage?
    
    public var rejectedAt: String?
    
    public var approvedAt: String?
    
    public var createdAt: String
    
    public var moderationResult: StreamChatMessageModerationResult?
    
    public var updatedAt: String
    
    public var custom: [String: RawJSON]?
    
    public var reason: String?
    
    public var reviewedAt: String?
    
    public var reviewedBy: StreamChatUserObject?
    
    public init(details: StreamChatFlagDetails?, moderationFeedback: StreamChatFlagFeedback?, user: StreamChatUserObject?, createdByAutomod: Bool, message: StreamChatMessage?, rejectedAt: String?, approvedAt: String?, createdAt: String, moderationResult: StreamChatMessageModerationResult?, updatedAt: String, custom: [String: RawJSON]?, reason: String?, reviewedAt: String?, reviewedBy: StreamChatUserObject?) {
        self.details = details
        
        self.moderationFeedback = moderationFeedback
        
        self.user = user
        
        self.createdByAutomod = createdByAutomod
        
        self.message = message
        
        self.rejectedAt = rejectedAt
        
        self.approvedAt = approvedAt
        
        self.createdAt = createdAt
        
        self.moderationResult = moderationResult
        
        self.updatedAt = updatedAt
        
        self.custom = custom
        
        self.reason = reason
        
        self.reviewedAt = reviewedAt
        
        self.reviewedBy = reviewedBy
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case details
        
        case moderationFeedback = "moderation_feedback"
        
        case user
        
        case createdByAutomod = "created_by_automod"
        
        case message
        
        case rejectedAt = "rejected_at"
        
        case approvedAt = "approved_at"
        
        case createdAt = "created_at"
        
        case moderationResult = "moderation_result"
        
        case updatedAt = "updated_at"
        
        case custom
        
        case reason
        
        case reviewedAt = "reviewed_at"
        
        case reviewedBy = "reviewed_by"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(moderationFeedback, forKey: .moderationFeedback)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdByAutomod, forKey: .createdByAutomod)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(rejectedAt, forKey: .rejectedAt)
        
        try container.encode(approvedAt, forKey: .approvedAt)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(moderationResult, forKey: .moderationResult)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
        
        try container.encode(reviewedBy, forKey: .reviewedBy)
    }
}
