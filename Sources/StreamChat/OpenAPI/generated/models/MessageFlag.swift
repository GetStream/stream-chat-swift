//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MessageFlag: Codable, Hashable {
    public var createdAt: Date
    
    public var createdByAutomod: Bool
    
    public var updatedAt: Date
    
    public var approvedAt: Date? = nil
    
    public var reason: String? = nil
    
    public var rejectedAt: Date? = nil
    
    public var reviewedAt: Date? = nil
    
    public var custom: [String: RawJSON]? = nil
    
    public var details: FlagDetails? = nil
    
    public var message: Message? = nil
    
    public var moderationFeedback: FlagFeedback? = nil
    
    public var moderationResult: MessageModerationResult? = nil
    
    public var reviewedBy: UserObject? = nil
    
    public var user: UserObject? = nil
    
    public init(createdAt: Date, createdByAutomod: Bool, updatedAt: Date, approvedAt: Date? = nil, reason: String? = nil, rejectedAt: Date? = nil, reviewedAt: Date? = nil, custom: [String: RawJSON]? = nil, details: FlagDetails? = nil, message: Message? = nil, moderationFeedback: FlagFeedback? = nil, moderationResult: MessageModerationResult? = nil, reviewedBy: UserObject? = nil, user: UserObject? = nil) {
        self.createdAt = createdAt
        
        self.createdByAutomod = createdByAutomod
        
        self.updatedAt = updatedAt
        
        self.approvedAt = approvedAt
        
        self.reason = reason
        
        self.rejectedAt = rejectedAt
        
        self.reviewedAt = reviewedAt
        
        self.custom = custom
        
        self.details = details
        
        self.message = message
        
        self.moderationFeedback = moderationFeedback
        
        self.moderationResult = moderationResult
        
        self.reviewedBy = reviewedBy
        
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
        
        case custom
        
        case details
        
        case message
        
        case moderationFeedback = "moderation_feedback"
        
        case moderationResult = "moderation_result"
        
        case reviewedBy = "reviewed_by"
        
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
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(moderationFeedback, forKey: .moderationFeedback)
        
        try container.encode(moderationResult, forKey: .moderationResult)
        
        try container.encode(reviewedBy, forKey: .reviewedBy)
        
        try container.encode(user, forKey: .user)
    }
}
