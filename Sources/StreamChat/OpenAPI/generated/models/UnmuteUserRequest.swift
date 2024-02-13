//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UnmuteUserRequest: Codable, Hashable {
    public var targetId: String
    public var targetIds: [String]
    public var timeout: Int? = nil
    public var userId: String? = nil
    public var user: UserObjectRequest? = nil

    public init(targetId: String, targetIds: [String], timeout: Int? = nil, userId: String? = nil, user: UserObjectRequest? = nil) {
        self.targetId = targetId
        self.targetIds = targetIds
        self.timeout = timeout
        self.userId = userId
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case targetId = "target_id"
        case targetIds = "target_ids"
        case timeout
        case userId = "user_id"
        case user
    }
}
