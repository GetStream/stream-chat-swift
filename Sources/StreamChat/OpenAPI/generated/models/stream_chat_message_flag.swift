//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageFlag: Codable, Hashable {
    public var rejectedAt: Date?
    
    public var approvedAt: Date?
    
    public var createdByAutomod: Bool
    
    public var user: StreamChatUserObject?
    
    public var custom: [String: RawJSON]?
    
    public var message: StreamChatMessage?
    
    public var reviewedAt: Date?
    
    public var updatedAt: Date
    
    public var reviewedBy: StreamChatUserObject?
    
    public var createdAt: Date
    
    public var details: StreamChatFlagDetails?
    
    public var moderationFeedback: StreamChatFlagFeedback?
    
    public var moderationResult: StreamChatMessageModerationResult?
    
    public var reason: String?
    
    public init(rejectedAt: Date?, approvedAt: Date?, createdByAutomod: Bool, user: StreamChatUserObject?, custom: [String: RawJSON]?, message: StreamChatMessage?, reviewedAt: Date?, updatedAt: Date, reviewedBy: StreamChatUserObject?, createdAt: Date, details: StreamChatFlagDetails?, moderationFeedback: StreamChatFlagFeedback?, moderationResult: StreamChatMessageModerationResult?, reason: String?) {
        self.rejectedAt = rejectedAt
        
        self.approvedAt = approvedAt
        
        self.createdByAutomod = createdByAutomod
        
        self.user = user
        
        self.custom = custom
        
        self.message = message
        
        self.reviewedAt = reviewedAt
        
        self.updatedAt = updatedAt
        
        self.reviewedBy = reviewedBy
        
        self.createdAt = createdAt
        
        self.details = details
        
        self.moderationFeedback = moderationFeedback
        
        self.moderationResult = moderationResult
        
        self.reason = reason
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case rejectedAt = "rejected_at"
        
        case approvedAt = "approved_at"
        
        case createdByAutomod = "created_by_automod"
        
        case user
        
        case custom
        
        case message
        
        case reviewedAt = "reviewed_at"
        
        case updatedAt = "updated_at"
        
        case reviewedBy = "reviewed_by"
        
        case createdAt = "created_at"
        
        case details
        
        case moderationFeedback = "moderation_feedback"
        
        case moderationResult = "moderation_result"
        
        case reason
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(rejectedAt, forKey: .rejectedAt)
        
        try container.encode(approvedAt, forKey: .approvedAt)
        
        try container.encode(createdByAutomod, forKey: .createdByAutomod)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(reviewedAt, forKey: .reviewedAt)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(reviewedBy, forKey: .reviewedBy)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(moderationFeedback, forKey: .moderationFeedback)
        
        try container.encode(moderationResult, forKey: .moderationResult)
        
        try container.encode(reason, forKey: .reason)
    }
}
