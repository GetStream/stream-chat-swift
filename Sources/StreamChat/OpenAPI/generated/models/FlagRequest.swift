//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct FlagRequest: Codable, Hashable {
    public var reason: String? = nil
    public var targetMessageId: String? = nil
    public var userId: String? = nil
    public var custom: [String: RawJSON]? = nil
    public var user: UserObjectRequest? = nil

    public init(reason: String? = nil, targetMessageId: String? = nil, userId: String? = nil, custom: [String: RawJSON]? = nil, user: UserObjectRequest? = nil) {
        self.reason = reason
        self.targetMessageId = targetMessageId
        self.userId = userId
        self.custom = custom
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case reason
        case targetMessageId = "target_message_id"
        case userId = "user_id"
        case custom
        case user
    }
}
