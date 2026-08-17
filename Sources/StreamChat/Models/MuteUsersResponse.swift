//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing the result of muting users.
public struct MuteUsersResponse: Sendable {
    /// The mutes which were created.
    public let mutes: [MutedUserDetails]?

    /// The ids of the users which could not be found.
    public let nonExistingUsers: [String]?

    init(
        mutes: [MutedUserDetails]?,
        nonExistingUsers: [String]?
    ) {
        self.mutes = mutes
        self.nonExistingUsers = nonExistingUsers
    }
}

/// A type representing a muted user.
public struct MutedUserDetails: Sendable {
    /// The date the mute was created.
    public let createdAt: Date

    /// The date the mute expires, if it has an expiration.
    public let expires: Date?

    /// The muted user.
    public let user: ChatUser?

    /// The date the mute was last updated.
    public let updatedAt: Date

    init(
        createdAt: Date,
        expires: Date?,
        user: ChatUser?,
        updatedAt: Date
    ) {
        self.createdAt = createdAt
        self.expires = expires
        self.user = user
        self.updatedAt = updatedAt
    }
}
