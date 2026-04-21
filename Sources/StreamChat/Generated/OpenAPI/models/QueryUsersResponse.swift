//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryUsersResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    /// Array of users as result of filters applied.
    var users: [FullUserResponse]

    init(duration: String, users: [FullUserResponse]) {
        self.duration = duration
        self.users = users
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case users
    }

    static func == (lhs: QueryUsersResponse, rhs: QueryUsersResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.users == rhs.users
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(users)
    }
}
