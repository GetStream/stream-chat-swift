//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageModerationResult: Codable, Hashable {
    public var action: String
    
    public var aiModerationResponse: StreamChatModerationResponse?
    
    public var createdAt: Date
    
    public var messageId: String
    
    public var moderationThresholds: StreamChatThresholds?
    
    public var updatedAt: Date
    
    public var userBadKarma: Bool
    
    public var userKarma: Double
    
    public var blockedWord: String?
    
    public var blocklistName: String?
    
    public var moderatedBy: String?
    
    public init(action: String, aiModerationResponse: StreamChatModerationResponse?, createdAt: Date, messageId: String, moderationThresholds: StreamChatThresholds?, updatedAt: Date, userBadKarma: Bool, userKarma: Double, blockedWord: String?, blocklistName: String?, moderatedBy: String?) {
        self.action = action
        
        self.aiModerationResponse = aiModerationResponse
        
        self.createdAt = createdAt
        
        self.messageId = messageId
        
        self.moderationThresholds = moderationThresholds
        
        self.updatedAt = updatedAt
        
        self.userBadKarma = userBadKarma
        
        self.userKarma = userKarma
        
        self.blockedWord = blockedWord
        
        self.blocklistName = blocklistName
        
        self.moderatedBy = moderatedBy
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        
        case aiModerationResponse = "ai_moderation_response"
        
        case createdAt = "created_at"
        
        case messageId = "message_id"
        
        case moderationThresholds = "moderation_thresholds"
        
        case updatedAt = "updated_at"
        
        case userBadKarma = "user_bad_karma"
        
        case userKarma = "user_karma"
        
        case blockedWord = "blocked_word"
        
        case blocklistName = "blocklist_name"
        
        case moderatedBy = "moderated_by"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(action, forKey: .action)
        
        try container.encode(aiModerationResponse, forKey: .aiModerationResponse)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(moderationThresholds, forKey: .moderationThresholds)
        
        try container.encode(updatedAt, forKey: .updatedAt)
        
        try container.encode(userBadKarma, forKey: .userBadKarma)
        
        try container.encode(userKarma, forKey: .userKarma)
        
        try container.encode(blockedWord, forKey: .blockedWord)
        
        try container.encode(blocklistName, forKey: .blocklistName)
        
        try container.encode(moderatedBy, forKey: .moderatedBy)
    }
}
