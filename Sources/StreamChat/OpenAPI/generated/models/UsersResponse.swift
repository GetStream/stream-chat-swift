//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UsersResponse: Codable, Hashable {
    public var duration: String
    
    public var users: [UserResponse?]
    
    public init(duration: String, users: [UserResponse?]) {
        self.duration = duration
        
        self.users = users
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case users
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(users, forKey: .users)
    }
}
