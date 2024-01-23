//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateUsersRequest: Codable, Hashable {
    public var users: [String: StreamChatUserObjectRequest?]
    
    public init(users: [String: StreamChatUserObjectRequest?]) {
        self.users = users
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case users
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(users, forKey: .users)
    }
}
