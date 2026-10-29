//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Request body for creating a user group
final class CreateUserGroupRequest: Sendable, Encodable, JSONEncodable {
    /// An optional description for the group
    let description: String?
    /// Optional user group ID. If not provided, a UUID v7 will be generated
    let id: String?
    /// Optional initial list of user IDs to add as members
    let memberIds: [String]?
    /// The user friendly name of the user group
    let name: String
    /// Optional team ID to scope the group to a team
    let teamId: String?

    init(
        description: String? = nil,
        id: String? = nil,
        memberIds: [String]? = nil,
        name: String,
        teamId: String? = nil
    ) {
        self.description = description
        self.id = id
        self.memberIds = memberIds
        self.name = name
        self.teamId = teamId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(memberIds, forKey: .memberIds)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(teamId, forKey: .teamId)
    }
}
