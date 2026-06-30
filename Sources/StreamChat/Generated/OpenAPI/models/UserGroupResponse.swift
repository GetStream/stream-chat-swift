//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserGroupResponse: Sendable, Codable, JSONEncodable {
    let createdAt: Date
    let createdBy: String?
    let description: String?
    let id: String
    let members: [UserGroupMemberPayload]?
    let name: String
    let teamId: String?
    let updatedAt: Date

    init(createdAt: Date, createdBy: String? = nil, description: String? = nil, id: String, members: [UserGroupMemberPayload]? = nil, name: String, teamId: String? = nil, updatedAt: Date) {
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.description = description
        self.id = id
        self.members = members
        self.name = name
        self.teamId = teamId
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case createdBy = "created_by"
        case description
        case id
        case members
        case name
        case teamId = "team_id"
        case updatedAt = "updated_at"
    }
}
