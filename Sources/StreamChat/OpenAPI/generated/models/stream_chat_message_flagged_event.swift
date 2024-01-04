//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageFlaggedEvent: Codable, Hashable {
    public var flag: StreamChatFlag?
    
    public var message: StreamChatMessage?
    
    public var threadParticipants: [StreamChatUserObject]?
    
    public var type: String
    
    public var user: StreamChatUserObject?
    
    public var cid: String
    
    public var createdAt: String
    
    public init(flag: StreamChatFlag?, message: StreamChatMessage?, threadParticipants: [StreamChatUserObject]?, type: String, user: StreamChatUserObject?, cid: String, createdAt: String) {
        self.flag = flag
        
        self.message = message
        
        self.threadParticipants = threadParticipants
        
        self.type = type
        
        self.user = user
        
        self.cid = cid
        
        self.createdAt = createdAt
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case flag
        
        case message
        
        case threadParticipants = "thread_participants"
        
        case type
        
        case user
        
        case cid
        
        case createdAt = "created_at"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(flag, forKey: .flag)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(threadParticipants, forKey: .threadParticipants)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(cid, forKey: .cid)
        
        try container.encode(createdAt, forKey: .createdAt)
    }
}
