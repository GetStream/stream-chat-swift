//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMessageFlagsResponse: Codable, Hashable {
    public var duration: String
    
    public var flags: [StreamChatMessageFlag?]
    
    public init(duration: String, flags: [StreamChatMessageFlag?]) {
        self.duration = duration
        
        self.flags = flags
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case flags
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(flags, forKey: .flags)
    }
}
