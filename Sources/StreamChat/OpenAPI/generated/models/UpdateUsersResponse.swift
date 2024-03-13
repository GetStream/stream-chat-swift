//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateUsersResponse: Codable, Hashable {
    public var duration: String
    public var users: [String: UserResponse]

    public init(duration: String, users: [String: UserResponse]) {
        self.duration = duration
        self.users = users
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case users
    }
}
