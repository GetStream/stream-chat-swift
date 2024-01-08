//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageFlag: Codable, Hashable {
    public var createdAt: String
    
    public var custom: [String: RawJSON]?
    
    public var moderationFeedback: StreamChatFlagFeedback?
    
    public var approvedAt: String?
    
    public var details: StreamChatFlagDetails?
    
    public var moderationResult: StreamChatMessageModerationResult?
    
    public var rejectedAt: String?
    
    public var reviewedAt: String?
    
    public var createdByAutomod: Bool
    
    public var user: StreamChatUserObject?
    
    public var updatedAt: String
    
    public var reason: String?
    
    public var reviewedBy: StreamChatUserObject?
    
    public var message: StreamChatMessage?
    
    public init(createdAt: String, custom: [String: RawJSON]?, moderationFeedback: StreamChatFlagFeedback?, approvedAt: String?, details: StreamChatFlagDetails?, moderationResult: StreamChatMessageModerationResult?, rejectedAt: String?, reviewedAt: String?, createdByAutomod: Bool, user: StreamChatUserObject?, updatedAt: String, reason: String?, reviewedBy: StreamChatUserObject?, message: StreamChatMessage?) {
        self.createdAt = createdAt
        
        self.custom = custom
        
        self.moderationFeedback = moderationFeedback
        
        self.approvedAt = approvedAt
        
        self.details = details
        
        self.moderationResult = moderationResult
        
        self.rejectedAt = rejectedAt
        
        self.reviewedAt = reviewedAt
        
        self.createdByAutomod = createdByAutomod
        
        self.user = user
        
        self.updatedAt = updatedAt
        
        self.reason = reason
        
        self.reviewedBy = reviewedBy
        
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        
        case custom
        
        case moderationFeedback = "moderation_feedback"
        
        case approvedAt = "approved_at"
        
        case details
        
        case moderationResult = "moderation_result"
        
        case rejectedAt = "rejected_at"
        
        case reviewedAt = "reviewed_at"
        
        case createdByAutomod = "created_by_automod"
        
        case user
        
        case updatedAt = "updated_at"
        
        case reason
        
        case reviewedBy = "reviewed_by"
        
        case message
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(moderationFeedback, forKey: .moderationFeedback)
        
        try container.encode(approvedAt, forKey: .approvedAt)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(moderationResult, forKey: .moderationResult)
        
        try container.encode(rejectedAt, forKey: .rejectedAt)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
        
        try container.encode(createdByAutomod, forKey: .createdByAutomod)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(reviewedBy, forKey: .reviewedBy)
        
        try container.encode(message, forKey: .message)
    }
}
