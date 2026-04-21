//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UnmuteResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: String
    /// A list of users that can't be found. Common cause for this is deleted users
    var nonExistingUsers: [String]?

    init(duration: String, nonExistingUsers: [String]? = nil) {
        self.duration = duration
        self.nonExistingUsers = nonExistingUsers
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case nonExistingUsers = "non_existing_users"
    }

    static func == (lhs: UnmuteResponse, rhs: UnmuteResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.nonExistingUsers == rhs.nonExistingUsers
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(nonExistingUsers)
    }
}
