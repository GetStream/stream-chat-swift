//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MuteResponse: Sendable, Decodable {
    /// Object with mutes (if multiple users were muted)
    let mutes: [MutedUserPayload]?
    /// A list of users that can't be found. Common cause for this is deleted users
    let nonExistingUsers: [String]?
    let ownUser: OwnUserResponse?

    init(
        mutes: [MutedUserPayload]? = nil,
        nonExistingUsers: [String]? = nil,
        ownUser: OwnUserResponse? = nil
    ) {
        self.mutes = mutes
        self.nonExistingUsers = nonExistingUsers
        self.ownUser = ownUser
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.mutes = try container.decodeArrayIfPresentIgnoringFailures(
            [MutedUserPayload].self,
            forKey: .mutes
        )
        self.nonExistingUsers = try container.decodeIfPresent(
            [String].self,
            forKey: .nonExistingUsers
        )
        self.ownUser = try container.decodeIfPresent(OwnUserResponse.self, forKey: .ownUser)
    }
}
