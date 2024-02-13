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
}
