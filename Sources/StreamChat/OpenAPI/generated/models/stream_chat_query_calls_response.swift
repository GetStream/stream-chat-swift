//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryCallsResponse: Codable, Hashable {
    public var prev: String?
    
    public var calls: [StreamChatCallStateResponseFields]
    
    public var duration: String
    
    public var next: String?
    
    public init(prev: String?, calls: [StreamChatCallStateResponseFields], duration: String, next: String?) {
        self.prev = prev
        
        self.calls = calls
        
        self.duration = duration
        
        self.next = next
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case prev
        
        case calls
        
        case duration
        
        case next
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(prev, forKey: .prev)
        
        try container.encode(calls, forKey: .calls)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(next, forKey: .next)
    }
}
