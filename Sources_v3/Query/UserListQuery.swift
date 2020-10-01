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
    public let filter: Filter
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting<UserListSortingKey>]
    /// A pagination.
    public var pagination: Pagination
    /// Query options.
    let options: QueryOptions = [.presence]
    
    /// Init a users query.
    /// - Parameters:
    ///   - filter: a users filter.
    ///   - sort: a sorting list for users.
    ///   - pagination: a users pagination.
    public init(
        filter: Filter,
        sort: [Sorting<UserListSortingKey>] = [],
        pagination: Pagination = [.usersPageSize]
    ) {
        if case .none = filter {}
        self.filter = filter
        self.sort = sort
        self.pagination = pagination
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filter, forKey: .filter)
        
        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }
        
        try pagination.encode(to: encoder)
        try options.encode(to: encoder)
    }
}
