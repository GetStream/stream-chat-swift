//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A namespace for the `FilterKey`s suitable to be used for `ChannelListQuery`. This scope is not aware of any extra data types.
public protocol AnyChannelListFilterScope {}

/// An extra-data-specific namespace for the `FilterKey`s suitable to be used for `ChannelListQuery`.
public struct ChannelListFilterScope: FilterScope, AnyChannelListFilterScope {}

public extension Filter where Scope: AnyChannelListFilterScope {
    /// Filter to match channels containing members with specified user ids.
    static func containMembers(userIds: [UserId]) -> Filter<Scope> {
        .in(.members, values: userIds)
    }

    /// Filter to match channels containing at least one message.
    static var nonEmpty: Filter<Scope> {
        .greater(.lastMessageAt, than: Date(timeIntervalSince1970: 0))
    }

    /// Filter to match channels that are not related to any team.
    static var noTeam: Filter<Scope> {
        .equal(.team, to: nil)
    }
}

extension Filter where Scope: AnyChannelListFilterScope {
    /// Computed var helping us determine the value of `hidden` filter.
    var hiddenFilterValue: Bool? {
        if `operator`.isGroupOperator {
            let filters = value as? [Filter] ?? []
            return filters.compactMap(\.hiddenFilterValue).first
        } else if `operator` == FilterOperator.equal.rawValue {
            return key == FilterKey<Scope, Bool>.hidden.rawValue ? (value as? Bool) : nil
        } else {
            return nil
        }
    }
}

// We don't want to expose `members` publicly because it can't be used with any other operator
// than `$in`. We expose it publicly via the `containMembers` filter helper.
extension FilterKey where Scope: AnyChannelListFilterScope {
    static var members: FilterKey<Scope, UserId> { .init(rawValue: "members", keyPathString: #keyPath(ChannelDTO.members.user.id)) }
}

/// Filter values to be used with `.invite` FilterKey.
public enum InviteFilterValue: String, FilterValue {
    case pending
    case accepted
    case rejected
}

/// Filter keys for channel list.
public extension FilterKey where Scope: AnyChannelListFilterScope {
    /// A filter key for matching the `cid` value.
    /// Supported operators: `in`, `equal`
    static var cid: FilterKey<Scope, ChannelId> { .init(rawValue: "cid", keyPathString: #keyPath(ChannelDTO.cid), valueMapper: { $0.rawValue }) }

    /// A filter key for matching the `id` value.
    /// Supported operators: `in`, `equal`
    /// - Warning: Querying by the channel Identifier should be done using the `cid` field as much as possible to optimize API performance.
    /// As the full channel ID, `cid`s are indexed everywhere in Stream database where `id` is not.
    static var id: FilterKey<Scope, String> { .init(rawValue: "id", keyPathString: #keyPath(ChannelDTO.cid)) }

    /// A filter key for matching the `name` value.
    static var name: FilterKey<Scope, String> { .init(rawValue: "name", keyPathString: #keyPath(ChannelDTO.name)) }

    /// A filter key for matching the `image` value.
    static var imageURL: FilterKey<Scope, URL> { .init(rawValue: "image", keyPathString: #keyPath(ChannelDTO.imageURL)) }

    /// A filter key for matching the `type` value.
    /// Supported operators: `in`, `equal`
    static var type: FilterKey<Scope, ChannelType> { .init(rawValue: "type", keyPathString: #keyPath(ChannelDTO.typeRawValue), valueMapper: { $0.rawValue }) }

    /// A filter key for matching the `lastMessageAt` value.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`, `notEqual`
    static var lastMessageAt: FilterKey<Scope, Date> { .init(rawValue: "last_message_at", keyPathString: #keyPath(ChannelDTO.lastMessageAt)) }

    /// A filter key for matching the `createdBy` value.
    /// Supported operators: `equal`
    static var createdBy: FilterKey<Scope, UserId> { .init(rawValue: "created_by_id", keyPathString: #keyPath(ChannelDTO.createdBy.id)) }
    /// A filter key for matching the `createdAt` value.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`, `notEqual`
    static var createdAt: FilterKey<Scope, Date> { .init(rawValue: "created_at", keyPathString: #keyPath(ChannelDTO.createdAt)) }

    /// A filter key for matching the `updatedAt` value.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`, `notEqual`
    static var updatedAt: FilterKey<Scope, Date> { .init(rawValue: "updated_at", keyPathString: #keyPath(ChannelDTO.updatedAt)) }

    /// A filter key for matching the `deletedAt` value.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`, `notEqual`
    static var deletedAt: FilterKey<Scope, Date> { .init(rawValue: "deleted_at", keyPathString: #keyPath(ChannelDTO.deletedAt)) }

    /// A filter key for querying hidden channels.
    /// Supported operators: `equal`
    // TODO: should it be using the ChannelPayload.isHidden or ChannelPayload.channel.isHidden
    static var hidden: FilterKey<Scope, Bool> { .init(rawValue: "hidden", keyPathString: #keyPath(ChannelDTO.isHidden)) }

    /// A filter key for matching the `frozen` value.
    /// Supported operators: `equal`
    static var frozen: FilterKey<Scope, Bool> { .init(rawValue: "frozen", keyPathString: #keyPath(ChannelDTO.isFrozen)) }

    /// A filter key for matching the `memberCount` value.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`, `notEqual`
    static var memberCount: FilterKey<Scope, Int> { .init(rawValue: "member_count", keyPathString: #keyPath(ChannelDTO.memberCount)) }

    /// A filter key for matching the `team` value.
    /// Supported operators: `equal`
    static var team: FilterKey<Scope, TeamId?> { .init(rawValue: "team", keyPathString: #keyPath(ChannelDTO.team)) }

    /// Filter for checking whether current user is joined the channel or not (through invite or directly)
    /// Supported operators: `equal`.
    static var joined: FilterKey<Scope, Bool> { .init(
        rawValue: "joined",
        keyPathString: #keyPath(ChannelDTO.membership),
        predicateMapper: { op, joined in
            let key = #keyPath(ChannelDTO.membership)
            switch op {
            case .equal:
                return NSPredicate(format: joined ? "\(key) != nil" : "\(key) == nil")
            default:
                return nil
            }
        }
    ) }

    /// Filter for checking whether current user has muted the channel
    /// Supported operators: `equal`.
    static var muted: FilterKey<Scope, Bool> { .init(
        rawValue: "muted",
        keyPathString: #keyPath(ChannelDTO.mute),
        predicateMapper: { op, muted in
            let key = #keyPath(ChannelDTO.mute)
            switch op {
            case .equal:
                return NSPredicate(format: muted ? "\(key) != nil" : "\(key) == nil")
            default:
                return nil
            }
        }
    ) }

    /// Filter for checking the status of the invite
    /// Supported operators: `equal`
    static var invite: FilterKey<Scope, InviteFilterValue> { "invite" }

    /// Filter for checking the `name` property of a user who is a member of the channel
    /// Supported operators: `equal`, `notEqual`, `autocomplete`
    /// - Warning: This filter is considerably expensive for the backend so avoid using this when possible.
    static var memberName: FilterKey<Scope, String> { .init(rawValue: "member.user.name", keyPathString: #keyPath(ChannelDTO.members.user.name), isCollectionFilter: true) }

    /// Filter for the time of the last message in the channel. If the channel has no messages, then the time the channel was created.
    /// Supported operators: `equal`, `greaterThan`, `lessThan`, `greaterOrEqual`, `lessOrEqual`, `notEqual`
    static var lastUpdatedAt: FilterKey<Scope, Date> { .init(rawValue: "last_updated", keyPathString: #keyPath(ChannelDTO.lastMessageAt)) }
}

/// A query is used for querying specific channels from backend.
/// You can specify filter, sorting, pagination, limit for fetched messages in channel and other options.
public struct ChannelListQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case sort
        case user = "user_details"
        case state
        case watch
        case presence
        case pagination
        case messagesLimit = "message_limit"
        case membersLimit = "member_limit"
    }

    /// A filter for the query (see `Filter`).
    public let filter: Filter<ChannelListFilterScope>
    /// A sorting for the query (see `Sorting`).
    public let sort: [Sorting<ChannelListSortingKey>]
    /// A pagination.
    public var pagination: Pagination
    /// A number of messages inside each channel.
    public let messagesLimit: Int
    /// Number of members inside each channel.
    public let membersLimit: Int
    /// Query options.
    public var options: QueryOptions = [.watch]

    /// Init a channels query.
    /// - Parameters:
    ///   - filter: a channels filter.
    ///   - sort: a sorting list for channels.
    ///   - pageSize: a page size for pagination.
    ///   - messagesLimit: a number of messages for the channel to be retrieved.
    public init(
        filter: Filter<ChannelListFilterScope>,
        sort: [Sorting<ChannelListSortingKey>] = [],
        pageSize: Int = .channelsPageSize,
        messagesLimit: Int = .messagesPageSize,
        membersLimit: Int = .channelMembersPageSize
    ) {
        self.filter = filter
        self.sort = sort
        pagination = Pagination(pageSize: pageSize)
        self.messagesLimit = messagesLimit
        self.membersLimit = membersLimit
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filter, forKey: .filter)

        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }

        try container.encode(messagesLimit, forKey: .messagesLimit)
        try container.encode(membersLimit, forKey: .membersLimit)
        try options.encode(to: encoder)
        try pagination.encode(to: encoder)
    }
}

extension ChannelListQuery: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Filter: \(filter) | Sort: \(sort)"
    }
}
