//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMessageResponse: Codable, Hashable {
    public var message: StreamChatMessage?
    
    public var duration: String
    
    public init(message: StreamChatMessage?, duration: String) {
        self.message = message
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case message
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(duration, forKey: .duration)
    }
}
