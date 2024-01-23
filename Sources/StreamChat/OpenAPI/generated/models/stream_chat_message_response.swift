//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageResponse: Codable, Hashable {
    public var duration: String
    
    public var message: StreamChatMessage? = nil
    
    public init(duration: String, message: StreamChatMessage? = nil) {
        self.duration = duration
        
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case message
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(message, forKey: .message)
    }
}
