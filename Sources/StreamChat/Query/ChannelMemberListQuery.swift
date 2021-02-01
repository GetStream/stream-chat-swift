//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A namespace for the `FilterKey`s suitable to be used for `ChannelMemberListQuery`. This scope is not aware of any
/// extra data types.
public protocol AnyMemberListFilterScope: AnyUserListFilterScope {}

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `ChannelMemberListQuery`.
///
/// - Note: `MemberListFilterScope` is a typealias of `_MemberListFilterScope` with the default extra data types.
/// If you want to use your custom extra data types, you should create your own `MemberListFilterScope`
/// typealias for `_MemberListFilterScope`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias MemberListFilterScope = _MemberListFilterScope<NoExtraData>

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `_ChannelMemberListQuery`.
///
/// - Note: `_MemberListFilterScope` type is not meant to be used directly.
/// If you don't use custom extra data types, use `MemberListFilterScope` typealias instead.
/// When using custom extra data types, you should create your own `MemberListFilterScope` typealias for `_MemberListFilterScope`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public class _MemberListFilterScope<ExtraData: UserExtraData>: _UserListFilterScope<ExtraData>, AnyMemberListFilterScope {}

/// Non extra-data-specific filer keys for member list.
public extension FilterKey where Scope: AnyMemberListFilterScope {
    /// A filter key for matching moderators of a channel.
    static var isModerator: FilterKey<Scope, Bool> { "is_moderator" }
}

/// A query type used for fetching channel members from the backend.
///
/// - Note: `ChannelMemberListQuery` is a typealias of `_ChannelMemberListQuery` with the default extra data types.
/// If you want to use your custom extra data types, you should create your own `ChannelMemberListQuery`
/// typealias for `_ChannelMemberListQuery`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChannelMemberListQuery = _ChannelMemberListQuery<NoExtraData>

/// A query type used for fetching channel members from the backend.
///
/// - Note: `_ChannelMemberListQuery` type is not meant to be used directly.
/// If you don't use custom extra data types, use `ChannelMemberListQuery` typealias instead.
/// When using custom extra data types, you should create your own `ChannelMemberListQuery` typealias for `_ChannelMemberListQuery`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public struct _ChannelMemberListQuery<ExtraData: UserExtraData>: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case sort
        case channelId = "id"
        case channelType = "type"
    }
    
    /// A channel identifier the members should be fetched for.
    public let cid: ChannelId
    /// A filter for the query (see `Filter`).
    public let filter: Filter<_MemberListFilterScope<ExtraData>>?
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting<ChannelMemberListSortingKey>]
    /// A pagination.
    public var pagination: Pagination
    
    /// Creates new `ChannelMemberListQuery` instance.
    /// - Parameters:
    ///   - cid: The channel identifier.
    ///   - filter: The members filter. Empty filter will return all users.
    ///   - sort: The sorting for members list.
    ///   - pageSize: The page size for pagination.
    public init(
        cid: ChannelId,
        filter: Filter<_MemberListFilterScope<ExtraData>>? = nil,
        sort: [Sorting<ChannelMemberListSortingKey>] = [],
        pageSize: Int = .channelMembersPageSize
    ) {
        self.cid = cid
        self.filter = filter
        self.sort = sort
        pagination = Pagination(pageSize: pageSize)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let filter = filter {
            try container.encode(filter, forKey: .filter)
        } else {
            try container.encode(EmptyObject(), forKey: .filter)
        }
        
        try container.encode(cid.id, forKey: .channelId)
        try container.encode(cid.type, forKey: .channelType)
        
        try pagination.encode(to: encoder)
        if !sort.isEmpty { try container.encode(sort, forKey: .sort) }
    }
}

extension _ChannelMemberListQuery {
    var queryHash: String {
        [
            cid.rawValue,
            filter?.filterHash,
            sort.map(\.description).joined()
        ].compactMap { $0 }.joined(separator: "-")
    }
}

extension _ChannelMemberListQuery {
    /// Builds `ChannelMemberListQuery` for a single member in a specific channel
    /// - Parameters:
    ///   - userId: The user identifier.
    ///   - cid: The channel identifier.
    /// - Returns: `ChannelMemberListQuery` for a specific user in a specific channel
    static func channelMember(userId: UserId, cid: ChannelId) -> Self {
        .init(cid: cid, filter: .equal("id", to: userId))
    }
}

// Backend expects empty object for "filter_conditions" in case no filter specified.
private struct EmptyObject: Encodable {}
