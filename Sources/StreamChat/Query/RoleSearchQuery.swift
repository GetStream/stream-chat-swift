//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type of roles to include when searching.
public enum RoleType: String, Sendable, Equatable {
    /// Roles that can be assigned to users.
    case user
    /// Roles that can be assigned within a channel.
    case channel
}

/// A query used for searching roles from the backend.
public struct RoleSearchQuery: Encodable, Sendable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case query
        case limit
        case includeGlobalRoles = "include_global_roles"
        case nameGreaterThan = "name_gt"
        case roleType = "role_type"
    }

    /// The search term used to match role names.
    public let query: String

    /// The maximum number of roles to return.
    public var limit: Int?

    /// Whether global (application-level) roles should be included in the results.
    public var includeGlobalRoles: Bool?

    /// Cursor: return roles with a name greater than this value.
    public var nameGreaterThan: String?

    /// When set, restricts the search to roles of the given type.
    /// When `nil`, both user- and channel-assignable roles are searched.
    public var roleType: RoleType?

    public init(
        query: String,
        limit: Int? = nil,
        includeGlobalRoles: Bool? = nil,
        nameGreaterThan: String? = nil,
        roleType: RoleType? = nil
    ) {
        self.query = query
        self.limit = limit
        self.includeGlobalRoles = includeGlobalRoles
        self.nameGreaterThan = nameGreaterThan
        self.roleType = roleType
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(query, forKey: .query)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(includeGlobalRoles, forKey: .includeGlobalRoles)
        try container.encodeIfPresent(nameGreaterThan, forKey: .nameGreaterThan)
        try container.encodeIfPresent(roleType?.rawValue, forKey: .roleType)
    }
}
