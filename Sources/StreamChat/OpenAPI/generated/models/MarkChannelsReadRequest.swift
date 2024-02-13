//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MarkChannelsReadRequest: Codable, Hashable {
    public var userId: String? = nil
    public var user: UserObjectRequest? = nil

    public init(userId: String? = nil, user: UserObjectRequest? = nil) {
        self.userId = userId
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userId = "user_id"
        case user
    }
}
