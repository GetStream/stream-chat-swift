//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A namespace for the `FilterKey`s suitable to be used for `UserListQuery`. This scope is not aware of any extra data types.
public protocol AnyUserListFilterScope {}

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `_UserListQuery`.
///
/// - Note: `UserListFilterScope` is a typealias of `_UserListFilterScope` with the default extra data types.
/// If you want to use your custom extra data types, you should create your own `UserListFilterScope`
/// typealias for `_UserListFilterScope`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias UserListFilterScope = _UserListFilterScope<NoExtraData>

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `_UserListQuery`.
///
/// - Note: `_UserListFilterScope` type is not meant to be used directly.
/// If you don't use custom extra data types, use `UserListFilterScope` typealias instead.
/// When using custom extra data types, you should create your own `UserListFilterScope` typealias for `_UserListFilterScope`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public class _UserListFilterScope<ExtraData: UserExtraData>: FilterScope, AnyUserListFilterScope {}

/// Non extra-data-specific filer keys for channel list.
public extension FilterKey where Scope: AnyUserListFilterScope {
    /// A filter key for matching the `id` value.
    static var id: FilterKey<Scope, UserId> { "id" }
    
    /// A filter key for matching the `name` value.
    static var name: FilterKey<Scope, String> { "name" }
    
    /// A filter key for matching the `image` value.
    static var imageURL: FilterKey<Scope, URL> { "image" }
    
    /// A filter key for matching the `role` value.
    static var role: FilterKey<Scope, UserRole> { "role" }
    
    /// A filter key for matching the `isOnline` value.
    static var isOnline: FilterKey<Scope, Bool> { "online" }
    
    /// A filter key for matching the `isBanned` value.
    static var isBanned: FilterKey<Scope, Bool> { "banned" }
    
    /// A filter key for matching the `createdAt` value.
    static var createdAt: FilterKey<Scope, Date> { "created_at" }
    
    /// A filter key for matching the `updatedAt` value.
    static var updatedAt: FilterKey<Scope, Date> { "updated_at" }
    
    /// A filter key for matching the `lastActiveAt` value.
    static var lastActiveAt: FilterKey<Scope, Date> { "last_active" }
    
    /// A filter key for matching the `isInvisible` value.
    static var isInvisible: FilterKey<Scope, Bool> { "invisible" }
    
    /// A filter key for matching the `unreadChannelsCount` value.
    static var unreadChannelsCount: FilterKey<Scope, Int> { "unread_channels" }
    
    /// A filter key for matching the `unreadMessagesCount` value.
    static var unreadMessagesCount: FilterKey<Scope, Int> { "total_unread_count" }
    
    /// A filter key for matching the `isAnonymous` value.
    static var isAnonymous: FilterKey<Scope, Bool> { "anon" }
    
    //    static var team: FilterKey<Scope, > { "team" }
}

/// A query is used for querying specific users from backend.
/// You can specify filter, sorting and pagination.
///
/// - Note: `UserListQuery` is a typealias of `_UserListQuery` with the default extra data types.
/// If you want to use your custom extra data types, you should create your own `UserListQuery` typealias for `_UserListQuery`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
typealias UserListQuery = _UserListQuery<NoExtraData>

/// A query is used for querying specific users from backend.
/// You can specify filter, sorting and pagination.
///
/// - Note: `_UserListQuery` type is not meant to be used directly.
/// If you don't use custom extra data types, use `UserListQuery` typealias instead.
/// When using custom extra data types, you should create your own `UserListQuery` typealias for `_UserListQuery`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public struct _UserListQuery<ExtraData: UserExtraData>: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case sort
        case pagination
    }
    
    /// A filter for the query (see `Filter`).
    public var filter: Filter<_UserListFilterScope<ExtraData>>?
    
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting<UserListSortingKey>]
    
    /// A pagination.
    public var pagination: Pagination?
    
    /// Query options. By default the query options contain `presence`.
    var options: QueryOptions = [.presence]
    
    /// Indicates if the query should be observed for new users.
    /// If set to true, newly created users in the database are automatically included in the query if they fit the predicate.
    var shouldBeUpdatedInBackground = true
    
    /// Init a users query.
    /// - Parameters:
    ///   - filter: a users filter. Empty filter will return all users.
    ///   - sort: a sorting list for users.
    ///   - pageSize: a page size for pagination.
    public init(
        filter: Filter<_UserListFilterScope<ExtraData>>? = nil,
        sort: [Sorting<UserListSortingKey>] = [],
        pageSize: Int = .usersPageSize
    ) {
        self.filter = filter
        self.sort = sort.appendingIdSortingKey()
        pagination = Pagination(pageSize: pageSize)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let filter = filter {
            try container.encode(filter, forKey: .filter)
        } else {
            try container.encode(EmptyObject(), forKey: .filter)
        }

        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }
        
        try pagination.map { try $0.encode(to: encoder) }
        try options.encode(to: encoder)
    }
}

extension _UserListQuery {
    /// Builds `UserListQuery` for a user with the provided `userId`
    /// - Parameter userId: The user identifier
    /// - Returns: `UserListQuery` for a specific user
    static func user(withID userId: UserId) -> Self {
        .init(filter: .equal(.id, to: userId))
    }
}

// Backend expects empty object for "filter_conditions" in case no filter specified.
private struct EmptyObject: Encodable {}
