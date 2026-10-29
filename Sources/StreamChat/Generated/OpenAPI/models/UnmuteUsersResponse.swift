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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.nonExistingUsers = try container.decodeIfPresent(
            [String].self,
            forKey: .nonExistingUsers
        )
    }
}
