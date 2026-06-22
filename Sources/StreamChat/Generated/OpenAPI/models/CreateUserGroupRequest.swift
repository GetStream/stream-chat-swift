//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateUserGroupRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// An optional description for the group
    var description: String?
    /// Optional user group ID. If not provided, a UUID v7 will be generated
    var id: String?
    /// Optional initial list of user IDs to add as members
    var memberIds: [String]?
    /// The user friendly name of the user group
    var name: String
    /// Optional team ID to scope the group to a team
    var teamId: String?

    init(description: String? = nil, id: String? = nil, memberIds: [String]? = nil, name: String, teamId: String? = nil) {
        self.description = description
        self.id = id
        self.memberIds = memberIds
        self.name = name
        self.teamId = teamId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case description
        case id
        case memberIds = "member_ids"
        case name
        case teamId = "team_id"
    }

    static func == (lhs: CreateUserGroupRequest, rhs: CreateUserGroupRequest) -> Bool {
        lhs.description == rhs.description &&
            lhs.id == rhs.id &&
            lhs.memberIds == rhs.memberIds &&
            lhs.name == rhs.name &&
            lhs.teamId == rhs.teamId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(description)
        hasher.combine(id)
        hasher.combine(memberIds)
        hasher.combine(name)
        hasher.combine(teamId)
    }
}
