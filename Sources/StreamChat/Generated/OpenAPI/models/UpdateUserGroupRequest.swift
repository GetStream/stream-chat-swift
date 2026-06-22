//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateUserGroupRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// The new description for the group
    var description: String?
    /// The new name of the user group
    var name: String?
    var teamId: String?

    init(description: String? = nil, name: String? = nil, teamId: String? = nil) {
        self.description = description
        self.name = name
        self.teamId = teamId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case description
        case name
        case teamId = "team_id"
    }

    static func == (lhs: UpdateUserGroupRequest, rhs: UpdateUserGroupRequest) -> Bool {
        lhs.description == rhs.description &&
            lhs.name == rhs.name &&
            lhs.teamId == rhs.teamId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(description)
        hasher.combine(name)
        hasher.combine(teamId)
    }
}
