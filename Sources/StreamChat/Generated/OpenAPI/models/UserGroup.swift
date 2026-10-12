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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.id = try container.decode(String.self, forKey: .id)
        self._members = try container.decodeIfPresent([UserGroupMember].self, forKey: .members)
        self.name = try container.decode(String.self, forKey: .name)
        self.teamId = try container.decodeIfPresent(String.self, forKey: .teamId)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

extension UserGroup: Hashable {
    public static func == (lhs: UserGroup, rhs: UserGroup) -> Bool {
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
