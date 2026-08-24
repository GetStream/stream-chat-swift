//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class UserGroup: Sendable, Decodable {
    public let createdAt: Date
    public let createdBy: String?
    public let description: String?
    public let id: String
    private let _members: [UserGroupMember]?
    public var members: [UserGroupMember] { _members ?? [] }
    public let name: String
    public let teamId: String?
    public let updatedAt: Date

    init(
        createdAt: Date,
        createdBy: String? = nil,
        description: String? = nil,
        id: String,
        members: [UserGroupMember]? = nil,
        name: String,
        teamId: String? = nil,
        updatedAt: Date
    ) {
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.description = description
        self.id = id
        self._members = members
        self.name = name
        self.teamId = teamId
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case createdBy = "created_by"
        case description
        case id
        case _members = "members"
        case name
        case teamId = "team_id"
        case updatedAt = "updated_at"
    }
}

extension UserGroup: Hashable {
    public static func == (
        lhs: UserGroup,
        rhs: UserGroup
    ) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.createdBy == rhs.createdBy &&
            lhs.description == rhs.description &&
            lhs.id == rhs.id &&
            lhs.members == rhs.members &&
            lhs.name == rhs.name &&
            lhs.teamId == rhs.teamId &&
            lhs.updatedAt == rhs.updatedAt
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(createdAt)
        hasher.combine(createdBy)
        hasher.combine(description)
        hasher.combine(id)
        hasher.combine(members)
        hasher.combine(name)
        hasher.combine(teamId)
        hasher.combine(updatedAt)
    }
}
