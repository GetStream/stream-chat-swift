//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MuteResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: String
    /// Object with mutes (if multiple users were muted)
    var mutes: [UserMuteResponse]?
    /// A list of users that can't be found. Common cause for this is deleted users
    var nonExistingUsers: [String]?
    var ownUser: OwnUserResponse?

    init(duration: String, mutes: [UserMuteResponse]? = nil, nonExistingUsers: [String]? = nil, ownUser: OwnUserResponse? = nil) {
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

    static func == (lhs: MuteResponse, rhs: MuteResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.mutes == rhs.mutes &&
            lhs.nonExistingUsers == rhs.nonExistingUsers &&
            lhs.ownUser == rhs.ownUser
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(mutes)
        hasher.combine(nonExistingUsers)
        hasher.combine(ownUser)
    }
}
