//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateMessageResponse: Codable, Hashable {
    public var pendingMessageMetadata: [String: RawJSON]?
    
    public var duration: String
    
    public var message: StreamChatMessage
    
    public init(pendingMessageMetadata: [String: RawJSON]?, duration: String, message: StreamChatMessage) {
        self.pendingMessageMetadata = pendingMessageMetadata
        
        self.duration = duration
        
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case pendingMessageMetadata = "pending_message_metadata"
        
        case duration
        
        case message
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(pendingMessageMetadata, forKey: .pendingMessageMetadata)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(message, forKey: .message)
    }
}
