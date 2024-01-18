//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPendingMessage: Codable, Hashable {
    public var channel: StreamChatChannel?
    
    public var message: StreamChatMessage?
    
    public var metadata: [String: RawJSON]?
    
    public var user: StreamChatUserObject?
    
    public init(channel: StreamChatChannel?, message: StreamChatMessage?, metadata: [String: RawJSON]?, user: StreamChatUserObject?) {
        self.channel = channel
        
        self.message = message
        
        self.metadata = metadata
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        
        case message
        
        case metadata
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(metadata, forKey: .metadata)
        
        try container.encode(user, forKey: .user)
    }
}
