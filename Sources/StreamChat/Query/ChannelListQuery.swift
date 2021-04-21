//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A namespace for the `FilterKey`s suitable to be used for `ChannelListQuery`. This scope is not aware of any extra data types.
public protocol AnyChannelListFilterScope {}

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `ChannelListQuery`.
///
/// - Note: `ChannelListFilterScope` is a typealias of `_ChannelListFilterScope` with the default extra data types.
/// If you want to use your custom extra data types, you should create your own `ChannelListFilterScope`
/// typealias for `_ChannelListFilterScope`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChannelListFilterScope = _ChannelListFilterScope<NoExtraData>

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `_ChannelListQuery`.
///
/// - Note: `_ChannelListFilterScope` type is not meant to be used directly.
/// If you don't use custom extra data types, use `ChannelListFilterScope` typealias instead.
/// When using custom extra data types, you should create your own `ChannelListFilterScope` typealias for `_ChannelListFilterScope`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public struct _ChannelListFilterScope<ExtraData: ChannelExtraData>: FilterScope, AnyChannelListFilterScope {}

public extension Filter where Scope: AnyChannelListFilterScope {
    /// Filter to match channels containing members with specified user ids.
    static func containMembers(userIds: [UserId]) -> Filter<Scope> {
        .in(.members, values: userIds)
    }
}

// We don't want to expose `members` publicly because it can't be used with any other operator
// then `$in`. We expose it publicly via the `containMembers` filter helper.
extension FilterKey where Scope: AnyChannelListFilterScope {
    static var members: FilterKey<Scope, UserId> { "members" }
}

/// Non extra-data-specific filer keys for channel list.
public extension FilterKey where Scope: AnyChannelListFilterScope {
    /// A filter key for matching the `cid` value.
    static var cid: FilterKey<Scope, ChannelId> { "cid" }
    
    /// A filter key for matching the `name` value.
    static var name: FilterKey<Scope, String> { "name" }
    
    /// A filter key for matching the `image` value.
    static var imageURL: FilterKey<Scope, URL> { "image" }
    
    /// A filter key for matching the `type` value.
    static var type: FilterKey<Scope, ChannelType> { "type" }
    
    /// A filter key for matching the `lastMessageAt` value.
    static var lastMessageAt: FilterKey<Scope, Date> { "last_message_at" }
    
    /// A filter key for matching the `createdBy` value.
    static var createdBy: FilterKey<Scope, UserId> { "created_by" }
    
    /// A filter key for matching the `createdAt` value.
    static var createdAt: FilterKey<Scope, Date> { "created_at" }
    
    /// A filter key for matching the `updatedAt` value.
    static var updatedAt: FilterKey<Scope, Date> { "updated_at" }
    
    /// A filter key for matching the `deletedAt` value.
    static var deletedAt: FilterKey<Scope, Date> { "deleted_at" }
    
    /// A filter key for matching the `frozen` value.
    static var frozen: FilterKey<Scope, Bool> { "frozen" }

    /// A filter key for matching the `memberCount` value.
    static var memberCount: FilterKey<Scope, Int> { "member_count" }
    
    /// A filter key for matching the `team` value.
    static var team: FilterKey<Scope, TeamId> { "team" }
}

/// A query is used for querying specific channels from backend.
/// You can specify filter, sorting, pagination, limit for fetched messages in channel and other options.
///
/// - Note: `ChannelListQuery` is a typealias of `_ChannelListQuery` with the default extra data types.
/// If you want to use your custom extra data types, you should create your own `ChannelListQuery` typealias
/// for `_ChannelListQuery`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChannelListQuery = _ChannelListQuery<NoExtraData>

/// A query is used for querying specific channels from backend.
/// You can specify filter, sorting, pagination, limit for fetched messages in channel and other options.
///
/// - Note: `_ChannelListQuery` type is not meant to be used directly.
/// If you don't use custom extra data types, use `ChannelListQuery` typealias instead.
/// When using custom extra data types, you should create your own `ChannelListQuery` typealias for `_ChannelListQuery`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public struct _ChannelListQuery<ExtraData: ChannelExtraData>: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case sort
        case user = "user_details"
        case state
        case watch
        case presence
        case pagination
        case messagesLimit = "message_limit"
    }
    
    /// A filter for the query (see `Filter`).
    public let filter: Filter<_ChannelListFilterScope<ExtraData>>
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting<ChannelListSortingKey>]
    /// A pagination.
    public var pagination: Pagination
    /// A number of messages inside each channel.
    public let messagesLimit: Int
    /// Query options.
    var options: QueryOptions = [.watch]
    
    /// Init a channels query.
    /// - Parameters:
    ///   - filter: a channels filter.
    ///   - sort: a sorting list for channels.
    ///   - pageSize: a page size for pagination.
    ///   - messagesLimit: a number of messages for the channel to be retrieved.
    public init(
        filter: Filter<_ChannelListFilterScope<ExtraData>>,
        sort: [Sorting<ChannelListSortingKey>] = [],
        pageSize: Int = .channelsPageSize,
        messagesLimit: Int = .messagesPageSize
    ) {
        self.filter = filter
        self.sort = sort.appendingCidSortingKey()
        pagination = Pagination(pageSize: pageSize)
        self.messagesLimit = messagesLimit
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filter, forKey: .filter)
        
        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }
        
        try container.encode(messagesLimit, forKey: .messagesLimit)
        try options.encode(to: encoder)
        try pagination.encode(to: encoder)
    }
}
