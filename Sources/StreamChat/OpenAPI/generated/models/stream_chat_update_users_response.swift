//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateUsersResponse: Codable, Hashable {
    public var users: [String: RawJSON]
    
    public var duration: String
    
    public init(users: [String: RawJSON], duration: String) {
        self.users = users
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case users
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(users, forKey: .users)
        
        try container.encode(duration, forKey: .duration)
    }
}
