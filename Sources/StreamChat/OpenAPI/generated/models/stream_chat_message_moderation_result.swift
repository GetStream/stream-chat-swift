//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageModerationResult: Codable, Hashable {
    public var action: String
    
    public var aiModerationResponse: StreamChatModerationResponse?
    
    public var blockedWord: String?
    
    public var createdAt: String
    
    public var moderationThresholds: StreamChatThresholds?
    
    public var updatedAt: String
    
    public var blocklistName: String?
    
    public var messageId: String
    
    public var moderatedBy: String?
    
    public var userBadKarma: Bool
    
    public var userKarma: Double
    
    public init(action: String, aiModerationResponse: StreamChatModerationResponse?, blockedWord: String?, createdAt: String, moderationThresholds: StreamChatThresholds?, updatedAt: String, blocklistName: String?, messageId: String, moderatedBy: String?, userBadKarma: Bool, userKarma: Double) {
        self.action = action
        
        self.aiModerationResponse = aiModerationResponse
        
        self.blockedWord = blockedWord
        
        self.createdAt = createdAt
        
        self.moderationThresholds = moderationThresholds
        
        self.updatedAt = updatedAt
        
        self.blocklistName = blocklistName
        
        self.messageId = messageId
        
        self.moderatedBy = moderatedBy
        
        self.userBadKarma = userBadKarma
        
        self.userKarma = userKarma
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        
        case aiModerationResponse = "ai_moderation_response"
        
        case blockedWord = "blocked_word"
        
        case createdAt = "created_at"
        
        case moderationThresholds = "moderation_thresholds"
        
        case updatedAt = "updated_at"
        
        case blocklistName = "blocklist_name"
        
        case messageId = "message_id"
        
        case moderatedBy = "moderated_by"
        
        case userBadKarma = "user_bad_karma"
        
        case userKarma = "user_karma"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(action, forKey: .action)
        
        try container.encode(aiModerationResponse, forKey: .aiModerationResponse)
        
        try container.encode(blockedWord, forKey: .blockedWord)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(moderationThresholds, forKey: .moderationThresholds)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(blocklistName, forKey: .blocklistName)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(moderatedBy, forKey: .moderatedBy)
        
        try container.encode(userBadKarma, forKey: .userBadKarma)
        
        try container.encode(userKarma, forKey: .userKarma)
    }
}
