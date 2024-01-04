//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryMembersResponse: Codable, Hashable {
    public var duration: String
    
    public var members: [StreamChatMemberResponse]
    
    public var next: String?
    
    public var prev: String?
    
    public init(duration: String, members: [StreamChatMemberResponse], next: String?, prev: String?) {
        self.duration = duration
        
        self.members = members
        
        self.next = next
        
        self.prev = prev
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case members
        
        case next
        
        case prev
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(next, forKey: .next)
        
        try container.encode(prev, forKey: .prev)
    }
}
