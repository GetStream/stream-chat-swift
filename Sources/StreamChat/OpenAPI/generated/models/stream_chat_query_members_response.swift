//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMembersResponse: Codable, Hashable {
    public var members: [StreamChatMemberResponse]
    
    public var next: String?
    
    public var prev: String?
    
    public var duration: String
    
    public init(members: [StreamChatMemberResponse], next: String?, prev: String?, duration: String) {
        self.members = members
        
        self.next = next
        
        self.prev = prev
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case members
        
        case next
        
        case prev
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(next, forKey: .next)
        
        try container.encode(prev, forKey: .prev)
        
        try container.encode(duration, forKey: .duration)
    }
}
