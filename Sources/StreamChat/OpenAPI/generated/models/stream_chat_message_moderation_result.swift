//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageModerationResult: Codable, Hashable {
    public var blocklistName: String?
    
    public var createdAt: Date
    
    public var moderatedBy: String?
    
    public var moderationThresholds: StreamChatThresholds?
    
    public var userBadKarma: Bool
    
    public var aiModerationResponse: StreamChatModerationResponse?
    
    public var blockedWord: String?
    
    public var messageId: String
    
    public var updatedAt: Date
    
    public var userKarma: Double
    
    public var action: String
    
    public init(blocklistName: String?, createdAt: Date, moderatedBy: String?, moderationThresholds: StreamChatThresholds?, userBadKarma: Bool, aiModerationResponse: StreamChatModerationResponse?, blockedWord: String?, messageId: String, updatedAt: Date, userKarma: Double, action: String) {
        self.blocklistName = blocklistName
        
        self.createdAt = createdAt
        
        self.moderatedBy = moderatedBy
        
        self.moderationThresholds = moderationThresholds
        
        self.userBadKarma = userBadKarma
        
        self.aiModerationResponse = aiModerationResponse
        
        self.blockedWord = blockedWord
        
        self.messageId = messageId
        
        self.updatedAt = updatedAt
        
        self.userKarma = userKarma
        
        self.action = action
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blocklistName = "blocklist_name"
        
        case createdAt = "created_at"
        
        case moderatedBy = "moderated_by"
        
        case moderationThresholds = "moderation_thresholds"
        
        case userBadKarma = "user_bad_karma"
        
        case aiModerationResponse = "ai_moderation_response"
        
        case blockedWord = "blocked_word"
        
        case messageId = "message_id"
        
        case updatedAt = "updated_at"
        
        case userKarma = "user_karma"
        
        case action
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(blocklistName, forKey: .blocklistName)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(moderatedBy, forKey: .moderatedBy)
        
        try container.encode(moderationThresholds, forKey: .moderationThresholds)
        
        try container.encode(userBadKarma, forKey: .userBadKarma)
        
        try container.encode(aiModerationResponse, forKey: .aiModerationResponse)
        
        try container.encode(blockedWord, forKey: .blockedWord)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(userKarma, forKey: .userKarma)
        
        try container.encode(action, forKey: .action)
    }
}
