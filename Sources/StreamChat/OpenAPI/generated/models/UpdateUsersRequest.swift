//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct UpdateUsersRequest: Codable, Hashable {
    public var users: [String: UserObjectRequest?]

    public init(users: [String: UserObjectRequest?]) {
        self.users = users
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case users
    }
}
