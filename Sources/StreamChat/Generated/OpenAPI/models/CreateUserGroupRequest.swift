//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case description
        case id
        case memberIds = "member_ids"
        case name
        case teamId = "team_id"
    }
}
