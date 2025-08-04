//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channel query.
public struct ChannelQuery: Encodable, Sendable {
    enum CodingKeys: String, CodingKey {
        case data
        case messages
        case members
        case watchers
    }

    /// Channel id this query handles.
    public let id: String?
    /// Channel type this query handles.
    public let type: ChannelType
    /// A pagination for messages (see `MessagesPagination`).
    public var pagination: MessagesPagination?
    /// A number of members for the channel to be retrieved.
    public var membersLimit: Int? { membersPagination?.pageSize }
    /// A number of watchers for the channel to be retrieved.
    public let watchersLimit: Int?
    /// A query options.
    public var options: QueryOptions = .all
    /// ChannelCreatePayload that is needed only when creating channel
    let channelPayload: ChannelEditDetailPayload?
    /// A pagination for members for the channel to be retrieved.
    let membersPagination: Pagination?

    /// `ChannelId` this query handles.
    /// If `id` part is missing then it's impossible to create valid `ChannelId`.
    public var cid: ChannelId? {
        id.map { ChannelId(type: type, id: $0) }
    }

    /// Init a channel query.
    /// - Parameters:
    ///   - cid: a channel cid.
    ///   - pageSize: a page size for pagination.
    ///   - paginationParameter: the pagination configuration.
    ///   - membersLimit: a number of members for the channel  to be retrieved.
    ///   - watchersLimit: a number of watchers for the channel to be retrieved.
    public init(
        cid: ChannelId,
        pageSize: Int? = .messagesPageSize,
        paginationParameter: PaginationParameter? = nil,
        membersLimit: Int? = nil,
        watchersLimit: Int? = nil
    ) {
        let membersPagination: Pagination? = {
            guard let membersLimit else { return nil }
            return Pagination(pageSize: membersLimit)
        }()
        let messagesPagination = MessagesPagination(pageSize: pageSize ?? .messagesPageSize, parameter: paginationParameter)
        self.init(
            cid: cid,
            pageSize: pageSize,
            messagesPagination: messagesPagination,
            membersPagination: membersPagination,
            watchersLimit: watchersLimit
        )
    }
    
    /// Init a channel query with base values.
    init(
        cid: ChannelId,
        pageSize: Int?,
        messagesPagination: MessagesPagination?,
        membersPagination: Pagination?,
        watchersLimit: Int?
    ) {
        id = cid.id
        type = cid.type
        channelPayload = nil
        pagination = messagesPagination
        self.membersPagination = membersPagination
        self.watchersLimit = watchersLimit
    }

    /// Init a channel query.
    /// - Parameters:
    ///   - channelPayload: a payload that has data needed for channel creation.
    init(channelPayload: ChannelEditDetailPayload) {
        id = channelPayload.id
        type = channelPayload.type
        self.channelPayload = channelPayload
        pagination = nil
        membersPagination = nil
        watchersLimit = nil
    }

    /// Init a channel query.
    /// - Parameters:
    ///   - cid: New `ChannelId` for channel query..
    ///   - channelQuery: ChannelQuery with old cid.
    init(cid: ChannelId, channelQuery: Self) {
        self.init(
            cid: cid,
            pageSize: channelQuery.pagination?.pageSize,
            messagesPagination: channelQuery.pagination,
            membersPagination: channelQuery.membersPagination,
            watchersLimit: channelQuery.watchersLimit
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try options.encode(to: encoder)

        // Only needed for channel creation
        try container.encodeIfPresent(channelPayload, forKey: .data)

        try pagination.map { try container.encode($0, forKey: .messages) }
        try membersPagination.map { try container.encode($0, forKey: .members) }
        try watchersLimit.map { try container.encode(Pagination(pageSize: $0), forKey: .watchers) }
    }
}

extension ChannelQuery: APIPathConvertible {
    var apiPath: String { cid?.apiPath ?? type.rawValue }
}

/// An answer for an invite to a channel.
struct ChannelInvitePayload: Encodable {
    struct Message: Encodable {
        let message: String?
    }

    private enum CodingKeys: String, CodingKey {
        case accept = "accept_invite"
        case reject = "reject_invite"
        case message
    }

    /// Accept the invite.
    let accept: Bool?
    /// Reject the invite.
    let reject: Bool?
    /// Additional message.
    let message: Message?
}
