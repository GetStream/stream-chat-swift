//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A query used for listing user groups from the backend.
public struct UserGroupListQuery: Encodable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case limit
        case idGreaterThan = "id_gt"
        case createdAtGreaterThan = "created_at_gt"
        case teamId = "team_id"
    }

    /// The maximum number of groups to return. When `nil`, the backend decides the default.
    public var limit: Int?

    /// Return groups with an ID greater than this value.
    public var idGreaterThan: String?

    /// Return groups created after this timestamp.
    public var createdAtGreaterThan: Date?

    /// When set, only groups scoped to this team are returned.
    public var teamId: String?

    public init(
        limit: Int? = nil,
        idGreaterThan: String? = nil,
        createdAtGreaterThan: Date? = nil,
        teamId: String? = nil
    ) {
        self.limit = limit
        self.idGreaterThan = idGreaterThan
        self.createdAtGreaterThan = createdAtGreaterThan
        self.teamId = teamId
    }
}

/// A query used for searching user groups by name prefix.
public struct UserGroupSearchQuery: Encodable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case query
        case limit
        case nameGreaterThan = "name_gt"
        case idGreaterThan = "id_gt"
        case teamId = "team_id"
    }

    /// The search term (1–255 characters).
    public let query: String

    /// The maximum number of groups to return. When `nil`, the backend decides the default.
    public var limit: Int?

    /// Return groups with a name greater than this value.
    public var nameGreaterThan: String?

    /// Return groups with an ID greater than this value.
    public var idGreaterThan: String?

    /// When set, only groups scoped to this team are returned.
    public var teamId: String?

    public init(
        query: String,
        limit: Int? = nil,
        nameGreaterThan: String? = nil,
        idGreaterThan: String? = nil,
        teamId: String? = nil
    ) {
        self.query = query
        self.limit = limit
        self.nameGreaterThan = nameGreaterThan
        self.idGreaterThan = idGreaterThan
        self.teamId = teamId
    }
}
