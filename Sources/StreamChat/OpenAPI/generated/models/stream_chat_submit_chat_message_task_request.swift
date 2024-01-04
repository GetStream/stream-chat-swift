//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSubmitChatMessageTaskRequest: Codable, Hashable {
    public var userId: String
    
    public var userName: String?
    
    public var channelId: String
    
    public var channelName: String?
    
    public var evaluations: [StreamChatEvaluationRequest?]?
    
    public var extra: [String: RawJSON]?
    
    public var messageId: String
    
    public var text: String
    
    public init(userId: String, userName: String?, channelId: String, channelName: String?, evaluations: [StreamChatEvaluationRequest?]?, extra: [String: RawJSON]?, messageId: String, text: String) {
        self.userId = userId
        
        self.userName = userName
        
        self.channelId = channelId
        
        self.channelName = channelName
        
        self.evaluations = evaluations
        
        self.extra = extra
        
        self.messageId = messageId
        
        self.text = text
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        
        case userName = "user_name"
        
        case channelId = "channel_id"
        
        case channelName = "channel_name"
        
        case evaluations
        
        case extra
        
        case messageId = "message_id"
        
        case text
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(userName, forKey: .userName)
        
        try container.encode(channelId, forKey: .channelId)
        
        try container.encode(channelName, forKey: .channelName)
        
        try container.encode(evaluations, forKey: .evaluations)
        
        try container.encode(extra, forKey: .extra)
        
        try container.encode(messageId, forKey: .messageId)
        
        try container.encode(text, forKey: .text)
    }
}
