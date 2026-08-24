//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateUserGroupRequest: Sendable, Encodable, JSONEncodable {
    /// The new description for the group
    let description: String?
    /// The new name of the user group
    let name: String?
    let teamId: String?

    init(
        description: String? = nil,
        name: String? = nil,
        teamId: String? = nil
    ) {
        self.description = description
        self.name = name
        self.teamId = teamId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case description
        case name
        case teamId = "team_id"
    }
}
