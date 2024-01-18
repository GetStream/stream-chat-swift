//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageFlag: Codable, Hashable {
    public var createdByAutomod: Bool
    
    public var user: StreamChatUserObject?
    
    public var createdAt: Date
    
    public var moderationResult: StreamChatMessageModerationResult?
    
    public var reason: String?
    
    public var reviewedBy: StreamChatUserObject?
    
    public var updatedAt: Date
    
    public var moderationFeedback: StreamChatFlagFeedback?
    
    public var rejectedAt: Date?
    
    public var approvedAt: Date?
    
    public var custom: [String: RawJSON]?
    
    public var details: StreamChatFlagDetails?
    
    public var message: StreamChatMessage?
    
    public var reviewedAt: Date?
    
    public init(createdByAutomod: Bool, user: StreamChatUserObject?, createdAt: Date, moderationResult: StreamChatMessageModerationResult?, reason: String?, reviewedBy: StreamChatUserObject?, updatedAt: Date, moderationFeedback: StreamChatFlagFeedback?, rejectedAt: Date?, approvedAt: Date?, custom: [String: RawJSON]?, details: StreamChatFlagDetails?, message: StreamChatMessage?, reviewedAt: Date?) {
        self.createdByAutomod = createdByAutomod
        
        self.user = user
        
        self.createdAt = createdAt
        
        self.moderationResult = moderationResult
        
        self.reason = reason
        
        self.reviewedBy = reviewedBy
        
        self.updatedAt = updatedAt
        
        self.moderationFeedback = moderationFeedback
        
        self.rejectedAt = rejectedAt
        
        self.approvedAt = approvedAt
        
        self.custom = custom
        
        self.details = details
        
        self.message = message
        
        self.reviewedAt = reviewedAt
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case createdByAutomod = "created_by_automod"
        
        case user
        
        case createdAt = "created_at"
        
        case moderationResult = "moderation_result"
        
        case reason
        
        case reviewedBy = "reviewed_by"
        
        case updatedAt = "updated_at"
        
        case moderationFeedback = "moderation_feedback"
        
        case rejectedAt = "rejected_at"
        
        case approvedAt = "approved_at"
        
        case custom
        
        case details
        
        case message
        
        case reviewedAt = "reviewed_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(createdByAutomod, forKey: .createdByAutomod)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(moderationResult, forKey: .moderationResult)
        
        try container.encode(reason, forKey: .reason)
        
        try container.encode(reviewedBy, forKey: .reviewedBy)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(moderationFeedback, forKey: .moderationFeedback)
        
        try container.encode(rejectedAt, forKey: .rejectedAt)
        
        try container.encode(approvedAt, forKey: .approvedAt)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
    }
}
