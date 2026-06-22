//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object describing a user group member JSON payload.
struct UserGroupMemberPayload: Decodable, Sendable {
    let groupId: String
    let userId: UserId
    let isAdmin: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case userId = "user_id"
        case isAdmin = "is_admin"
        case createdAt = "created_at"
    }

    init(
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

    func asModel() -> UserGroupMember {
        UserGroupMember(
            groupId: groupId,
            userId: userId,
            isAdmin: isAdmin,
            createdAt: createdAt
        )
    }
}

/// An object describing a user group JSON payload.
struct UserGroupPayload: Decodable, Sendable {
    let id: String
    let name: String
    let description: String?
    let teamId: String?
    let members: [UserGroupMemberPayload]
    let createdAt: Date
    let updatedAt: Date
    let createdBy: UserId?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case teamId = "team_id"
        case members
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        teamId = try container.decodeIfPresent(String.self, forKey: .teamId)
        members = try container.decodeIfPresent([UserGroupMemberPayload].self, forKey: .members) ?? []
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        createdBy = try container.decodeIfPresent(UserId.self, forKey: .createdBy)
    }

    init(
        id: String,
        name: String,
        description: String? = nil,
        teamId: String? = nil,
        members: [UserGroupMemberPayload] = [],
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

    func asModel() -> UserGroup {
        UserGroup(
            id: id,
            name: name,
            description: description,
            teamId: teamId,
            members: members.map { $0.asModel() },
            createdAt: createdAt,
            updatedAt: updatedAt,
            createdBy: createdBy
        )
    }
}

/// An object describing a user group mention JSON payload (e.g. inside a message).
struct UserGroupMentionPayload: Decodable, Sendable {
    let id: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
    }

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }

    func asModel() -> UserGroupMention {
        UserGroupMention(id: id, name: name)
    }
}

/// A response containing a list of user groups.
struct UserGroupListPayload: Decodable, Sendable {
    let userGroups: [UserGroupPayload]

    enum CodingKeys: String, CodingKey {
        case userGroups = "user_groups"
    }
}

/// A response containing a single user group.
struct UserGroupPayloadResponse: Decodable, Sendable {
    let userGroup: UserGroupPayload

    enum CodingKeys: String, CodingKey {
        case userGroup = "user_group"
    }
}

/// A request body for creating a user group.
struct CreateUserGroupRequestBody: Encodable, Sendable {
    let id: String?
    let name: String
    let description: String?
    let teamId: String?
    let memberIds: [UserId]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case teamId = "team_id"
        case memberIds = "member_ids"
    }

    init(
        id: String? = nil,
        name: String,
        description: String? = nil,
        teamId: String? = nil,
        memberIds: [UserId] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.teamId = teamId
        self.memberIds = memberIds
    }
}

/// A request body for updating a user group.
struct UpdateUserGroupRequestBody: Encodable, Sendable {
    let name: String?
    let description: String?
    let teamId: String?

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case teamId = "team_id"
    }

    init(
        name: String? = nil,
        description: String? = nil,
        teamId: String? = nil
    ) {
        self.name = name
        self.description = description
        self.teamId = teamId
    }
}

/// A request body for adding or removing members from a user group.
struct UserGroupMembersRequestBody: Encodable, Sendable {
    let memberIds: [UserId]
    let asAdmin: Bool?
    let teamId: String?

    enum CodingKeys: String, CodingKey {
        case memberIds = "member_ids"
        case asAdmin = "as_admin"
        case teamId = "team_id"
    }

    init(
        memberIds: [UserId],
        asAdmin: Bool? = nil,
        teamId: String? = nil
    ) {
        self.memberIds = memberIds
        self.asAdmin = asAdmin
        self.teamId = teamId
    }
}
