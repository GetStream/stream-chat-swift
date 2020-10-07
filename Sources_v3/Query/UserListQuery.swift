//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A query is used for querying specific users from backend.
/// You can specify filter, sorting and pagination.
public struct UserListQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case sort
        case presence
        case pagination
    }
    
    /// A filter for the query (see `Filter`).
    public let filter: Filter?
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting<UserListSortingKey>]
    /// A pagination.
    public var pagination: Pagination
    /// Query options.
    let options: QueryOptions = [.presence]
    
    /// Init a users query.
    /// - Parameters:
    ///   - filter: a users filter. Empty filter will return all users.
    ///   - sort: a sorting list for users.
    ///   - pagination: a users pagination.
    public init(
        filter: Filter? = nil,
        sort: [Sorting<UserListSortingKey>] = [],
        pagination: Pagination = [.usersPageSize]
    ) {
        self.filter = filter
        self.sort = sort
        self.pagination = pagination
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let filter = filter {
            try container.encode(filter, forKey: .filter)
        } else {
            // Backend expects empty object for "filter_conditions" in case no filter specified.
            struct EmptyObject: Encodable {}
            try container.encode(EmptyObject(), forKey: .filter)
        }

        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }
        
        try pagination.encode(to: encoder)
        try options.encode(to: encoder)
    }
}

extension UserListQuery {
    /// Builds `UserListQuery` for a user with the provided `userId`
    /// - Parameter userId: The user identifier
    /// - Returns: `UserListQuery` for a specific user
    static func user(withID userId: UserId) -> Self {
        .init(filter: .equal("id", to: userId))
    }
}
