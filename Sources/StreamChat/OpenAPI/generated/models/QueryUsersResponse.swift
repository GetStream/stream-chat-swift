//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct QueryUsersResponse: Codable, Hashable {
    public var duration: String
    public var users: [QueryUserResult]

    public init(duration: String, users: [QueryUserResult]) {
        self.duration = duration
        self.users = users
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case users
    }
}
