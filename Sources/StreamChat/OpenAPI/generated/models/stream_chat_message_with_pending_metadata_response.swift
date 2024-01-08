//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageWithPendingMetadataResponse: Codable, Hashable {
    public var message: StreamChatMessage?
    
    public var pendingMessageMetadata: [String: RawJSON]?
    
    public var duration: String
    
    public init(message: StreamChatMessage?, pendingMessageMetadata: [String: RawJSON]?, duration: String) {
        self.message = message
        
        self.pendingMessageMetadata = pendingMessageMetadata
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        
        case pendingMessageMetadata = "pending_message_metadata"
        
        case duration
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(pendingMessageMetadata, forKey: .pendingMessageMetadata)
        
        try container.encode(duration, forKey: .duration)
    }
}
