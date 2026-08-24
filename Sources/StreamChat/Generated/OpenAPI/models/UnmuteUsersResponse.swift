//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UnmuteUsersResponse: Sendable, Decodable {
    /// A list of users that can't be found. Common cause for this is deleted users
    public let nonExistingUsers: [String]?

    init(nonExistingUsers: [String]? = nil) {
        self.nonExistingUsers = nonExistingUsers
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case nonExistingUsers = "non_existing_users"
    }
}
