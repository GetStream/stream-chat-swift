//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MuteResponse: Sendable, Codable, JSONEncodable {
    let duration: String
    /// Object with mutes (if multiple users were muted)
    let mutes: [MutedUserPayload]?
    /// A list of users that can't be found. Common cause for this is deleted users
    let nonExistingUsers: [String]?
    let ownUser: OwnUserResponse?

    init(
        duration: String,
        mutes: [MutedUserPayload]? = nil,
        nonExistingUsers: [String]? = nil,
        ownUser: OwnUserResponse? = nil
    ) {
        self.duration = duration
        self.mutes = mutes
        self.nonExistingUsers = nonExistingUsers
        self.ownUser = ownUser
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case mutes
        case nonExistingUsers = "non_existing_users"
        case ownUser = "own_user"
    }
}
