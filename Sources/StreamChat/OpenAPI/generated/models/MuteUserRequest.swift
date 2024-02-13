//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MuteUserRequest: Codable, Hashable {
    public var targetIds: [String]
    public var timeout: Int? = nil
    public var userId: String? = nil
    public var user: UserObjectRequest? = nil

    public init(targetIds: [String], timeout: Int? = nil, userId: String? = nil, user: UserObjectRequest? = nil) {
        self.targetIds = targetIds
        self.timeout = timeout
        self.userId = userId
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case targetIds = "target_ids"
        case timeout
        case userId = "user_id"
        case user
    }
}
