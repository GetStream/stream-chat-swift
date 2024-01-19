//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryCallsResponse: Codable, Hashable {
    public var calls: [StreamChatCallStateResponseFields]
    
    public var duration: String
    
    public var next: String?
    
    public var prev: String?
    
    public init(calls: [StreamChatCallStateResponseFields], duration: String, next: String?, prev: String?) {
        self.calls = calls
        
        self.duration = duration
        
        self.next = next
        
        self.prev = prev
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case calls
        
        case duration
        
        case next
        
        case prev
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(calls, forKey: .calls)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(next, forKey: .next)
        
        try container.encode(prev, forKey: .prev)
    }
}
