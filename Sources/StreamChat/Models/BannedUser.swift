//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing a ban of a user.
public struct BannedUser: Sendable {
    /// The banned user.
    public let user: ChatUser

    /// The user who created the ban.
    public let bannedBy: ChatUser?

    /// The channel the ban is scoped to. It is `nil` when the user is banned application-wide.
    public let cid: ChannelId?

    /// The date the ban was created.
    public let createdAt: Date

    /// The date the ban expires. It is `nil` when the ban does not expire.
    public let expiresAt: Date?

    /// The reason the ban was created with.
    public let reason: String?

    /// A Boolean value indicating whether the ban is a shadow ban.
    ///
    /// A shadow banned user can still send messages, but they are only visible to the author.
    public let isShadowBan: Bool

    init(
        user: ChatUser,
        bannedBy: ChatUser?,
        cid: ChannelId?,
        createdAt: Date,
        expiresAt: Date?,
        reason: String?,
        isShadowBan: Bool
    ) {
        self.user = user
        self.bannedBy = bannedBy
        self.cid = cid
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.reason = reason
        self.isShadowBan = isShadowBan
    }
}
