//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUnblockUserRequest: Codable, Hashable {
    public var userId: String
    
    public init(userId: String) {
        self.userId = userId
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(userId, forKey: .userId)
    }
}
