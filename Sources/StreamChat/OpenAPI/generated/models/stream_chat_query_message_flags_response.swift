//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMessageFlagsResponse: Codable, Hashable {
    public var flags: [StreamChatMessageFlag?]
    
    public var duration: String
    
    public init(flags: [StreamChatMessageFlag?], duration: String) {
        self.flags = flags
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case flags
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(flags, forKey: .flags)
        
        try container.encode(duration, forKey: .duration)
    }
}
