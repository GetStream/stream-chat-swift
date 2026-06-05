//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A named collection of users that can be mentioned in a channel.
public struct UserGroup: Equatable, Identifiable, Sendable {
    /// The group identifier.
    public let id: String

    /// The display name of the group.
    public let name: String

    /// An optional description of the group.
    public let description: String?

    /// The team identifier when the group is team-scoped.
    public let teamId: String?

    /// The members of the group.
    public let members: [UserGroupMember]

    /// The date when the group was created.
    public let createdAt: Date

    /// The date when the group was last updated.
    public let updatedAt: Date

    /// The identifier of the user who created the group.
    public let createdBy: UserId?

    public init(
        id: String,
        name: String,
        description: String? = nil,
        teamId: String? = nil,
        members: [UserGroupMember] = [],
        createdAt: Date,
        updatedAt: Date,
        createdBy: UserId? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.teamId = teamId
        self.members = members
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.createdBy = createdBy
    }
}

/// A member of a user group.
public struct UserGroupMember: Equatable, Sendable {
    /// The group identifier.
    public let groupId: String

    /// The user identifier.
    public let userId: UserId

    /// Whether the member is a group admin.
    public let isAdmin: Bool

    /// The date when the member was added to the group.
    public let createdAt: Date

    public init(
        groupId: String,
        userId: UserId,
        isAdmin: Bool,
        createdAt: Date
    ) {
        self.groupId = groupId
        self.userId = userId
        self.isAdmin = isAdmin
        self.createdAt = createdAt
    }
}
