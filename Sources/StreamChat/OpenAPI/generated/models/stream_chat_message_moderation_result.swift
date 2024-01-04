//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageModerationResult: Codable, Hashable {
    public var aiModerationResponse: StreamChatModerationResponse?
    
    public var blockedWord: String?
    
    public var createdAt: String
    
    public var messageId: String
    
    public var userBadKarma: Bool
    
    public var action: String
    
    public var blocklistName: String?
    
    public var moderatedBy: String?
    
    public var moderationThresholds: StreamChatThresholds?
    
    public var updatedAt: String
    
    public var userKarma: Double
    
    public init(aiModerationResponse: StreamChatModerationResponse?, blockedWord: String?, createdAt: String, messageId: String, userBadKarma: Bool, action: String, blocklistName: String?, moderatedBy: String?, moderationThresholds: StreamChatThresholds?, updatedAt: String, userKarma: Double) {
        self.aiModerationResponse = aiModerationResponse
        
        self.blockedWord = blockedWord
        
        self.createdAt = createdAt
        
        self.messageId = messageId
        
        self.userBadKarma = userBadKarma
        
        self.action = action
        
        self.blocklistName = blocklistName
        
        self.moderatedBy = moderatedBy
        
        self.moderationThresholds = moderationThresholds
        
        self.updatedAt = updatedAt
        
        self.userKarma = userKarma
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case aiModerationResponse = "ai_moderation_response"
        
        case blockedWord = "blocked_word"
        
        case createdAt = "created_at"
        
        case messageId = "message_id"
        
        case userBadKarma = "user_bad_karma"
        
        case action
        
        case blocklistName = "blocklist_name"
        
        case moderatedBy = "moderated_by"
        
        case moderationThresholds = "moderation_thresholds"
        
        case updatedAt = "updated_at"
        
        case userKarma = "user_karma"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(aiModerationResponse, forKey: .aiModerationResponse)
        
        try container.encode(blockedWord, forKey: .blockedWord)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(userBadKarma, forKey: .userBadKarma)
        
        try container.encode(action, forKey: .action)
        
        try container.encode(blocklistName, forKey: .blocklistName)
        
        try container.encode(moderatedBy, forKey: .moderatedBy)
        
        try container.encode(moderationThresholds, forKey: .moderationThresholds)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(userKarma, forKey: .userKarma)
    }
}
