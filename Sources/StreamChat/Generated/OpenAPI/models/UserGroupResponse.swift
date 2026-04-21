//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UserGroupResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var createdAt: Date
    var createdBy: String?
    var description: String?
    var id: String
    var members: [UserGroupMember]?
    var name: String
    var teamId: String?
    var updatedAt: Date

    init(createdAt: Date, createdBy: String? = nil, description: String? = nil, id: String, members: [UserGroupMember]? = nil, name: String, teamId: String? = nil, updatedAt: Date) {
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

    static func == (lhs: UserGroupResponse, rhs: UserGroupResponse) -> Bool {
        lhs.createdAt == rhs.createdAt &&
            lhs.createdBy == rhs.createdBy &&
            lhs.description == rhs.description &&
            lhs.id == rhs.id &&
            lhs.members == rhs.members &&
            lhs.name == rhs.name &&
            lhs.teamId == rhs.teamId &&
            lhs.updatedAt == rhs.updatedAt
    }

    func hash(into hasher: inout Hasher) {
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
