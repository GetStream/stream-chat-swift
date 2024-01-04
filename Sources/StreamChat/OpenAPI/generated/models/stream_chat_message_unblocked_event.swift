//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageUnblockedEvent: Codable, Hashable {
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var cid: String
    
    public var createdAt: String
    
    public var message: StreamChatMessage?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public init(type: String, user: StreamChatUserObject?, cid: String, createdAt: String, message: StreamChatMessage?, threadParticipants: [StreamChatUserObject]?) {
        self.type = type
        
        self.user = user
        
        self.cid = cid
        
        self.createdAt = createdAt
        
        self.message = message
        
        self.threadParticipants = threadParticipants
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case user
        
        case cid
        
        case createdAt = "created_at"
        
        case message
        
        case threadParticipants = "thread_participants"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
    }
}
