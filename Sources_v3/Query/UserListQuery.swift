//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// An users query.
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
    public let options: QueryOptions
    
    /// Init a users query.
    /// - Parameters:
    ///   - filter: a users filter.
    ///   - sort: a sorting list for users.
    ///   - pagination: a users pagination.
    ///   - options: a query options (see `QueryOptions`).
    public init(
        filter: Filter,
        sort: [Sorting<UserListSortingKey>] = [],
        pagination: Pagination = [.usersPageSize],
        options: QueryOptions = []
    ) {
        if case .none = filter {}
        self.filter = filter
        self.sort = sort
        self.pagination = pagination
        self.options = options
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filter, forKey: .filter)
        
        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }
        
        try options.encode(to: encoder)
        try pagination.encode(to: encoder)
    }
}
