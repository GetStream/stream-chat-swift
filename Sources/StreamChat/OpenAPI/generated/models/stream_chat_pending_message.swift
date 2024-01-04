//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPendingMessage: Codable, Hashable {
    public var message: StreamChatMessage?
    
    public var metadata: [String: RawJSON]?
    
    public var user: StreamChatUserObject?
    
    public var channel: StreamChatChannel?
    
    public init(message: StreamChatMessage?, metadata: [String: RawJSON]?, user: StreamChatUserObject?, channel: StreamChatChannel?) {
        self.message = message
        
        self.metadata = metadata
        
        self.user = user
        
        self.channel = channel
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        
        case metadata
        
        case user
        
        case channel
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(metadata, forKey: .metadata)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channel, forKey: .channel)
    }
}
