//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatPendingMessage: Codable, Hashable {
    public var user: StreamChatUserObject?
    
    public var channel: StreamChatChannel?
    
    public var message: StreamChatMessage?
    
    public var metadata: [String: RawJSON]?
    
    public init(user: StreamChatUserObject?, channel: StreamChatChannel?, message: StreamChatMessage?, metadata: [String: RawJSON]?) {
        self.user = user
        
        self.channel = channel
        
        self.message = message
        
        self.metadata = metadata
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case channel
        
        case message
        
        case metadata
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(channel, forKey: .channel)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(metadata, forKey: .metadata)
    }
}
