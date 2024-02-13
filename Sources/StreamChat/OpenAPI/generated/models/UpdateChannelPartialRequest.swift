//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateChannelPartialRequest: Codable, Hashable {
    public var unset: [String]
    public var set: [String: RawJSON]
    public var userId: String? = nil
    public var user: UserObjectRequest? = nil

    public init(unset: [String], set: [String: RawJSON], userId: String? = nil, user: UserObjectRequest? = nil) {
        self.unset = unset
        self.set = set
        self.userId = userId
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case unset
        case set
        case userId = "user_id"
        case user
    }
}
