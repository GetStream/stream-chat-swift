//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPendingMessage: Codable, Hashable {
    public var metadata: [String: RawJSON]?
    
    public var user: StreamChatUserObject?
    
    public var channel: StreamChatChannel?
    
    public var message: StreamChatMessage?
    
    public init(metadata: [String: RawJSON]?, user: StreamChatUserObject?, channel: StreamChatChannel?, message: StreamChatMessage?) {
        self.metadata = metadata
        
        self.user = user
        
        self.channel = channel
        
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case metadata
        
        case user
        
        case channel
        
        case message
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(metadata, forKey: .metadata)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(message, forKey: .message)
    }
}
