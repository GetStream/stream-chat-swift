//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateMessageResponse: Codable, Hashable {
    public var duration: String
    
    public var message: StreamChatMessage
    
    public var pendingMessageMetadata: [String: RawJSON]?
    
    public init(duration: String, message: StreamChatMessage, pendingMessageMetadata: [String: RawJSON]?) {
        self.duration = duration
        
        self.message = message
        
        self.pendingMessageMetadata = pendingMessageMetadata
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case message
        
        case pendingMessageMetadata = "pending_message_metadata"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(pendingMessageMetadata, forKey: .pendingMessageMetadata)
    }
}
