//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channel query.
///
/// - Note: `ChannelQuery` is a typealias of `_ChannelQuery` with the default extra data types.
/// If you want to use your custom extra data types, you should create your own `ChannelQuery`
/// typealias for `_ChannelQuery`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public typealias ChannelQuery = _ChannelQuery<NoExtraData>

/// A channel query.
///
/// - Note: `_ChannelQuery` type is not meant to be used directly.
/// If you don't use custom extra data types, use `ChannelQuery` typealias instead.
/// When using custom extra data types, you should create your own `ChannelQuery` typealias for `_ChannelQuery`.
///
/// Learn more about using custom extra data in our [cheat sheet](https://github.com/GetStream/stream-chat-swift/wiki/Cheat-Sheet#working-with-extra-data).
///
public struct _ChannelQuery<ExtraData: ExtraDataTypes>: Encodable {
    private enum CodingKeys: String, CodingKey {
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
    public let membersLimit: Int?
    /// A number of watchers for the channel to be retrieved.
    public let watchersLimit: Int?
    /// A query options.
    var options: QueryOptions = .all
    /// ChannelCreatePayload that is needed only when creating channel
    let channelPayload: ChannelEditDetailPayload<ExtraData>?
    
    /// `ChannelId` this query handles.
    /// If `id` part is missing then it's impossible to create valid `ChannelId`.
    public var cid: ChannelId? {
        id.map { ChannelId(type: type, id: $0) }
    }

    /// Init a channel query.
    /// - Parameters:
    ///   - cid: a channel cid.
    ///   - pageSize: a page size for pagination.
    ///   - paginationOptions: an advanced options for pagination. (see `PaginationOption`)
    ///   - membersLimit: a number of members for the channel  to be retrieved.
    ///   - watchersLimit: a number of watchers for the channel to be retrieved.
    public init(
        cid: ChannelId,
        pageSize: Int? = .messagesPageSize,
        paginationParameter: PaginationParameter? = nil,
        membersLimit: Int? = nil,
        watchersLimit: Int? = nil
    ) {
        id = cid.id
        type = cid.type
        channelPayload = nil
        
        pagination = MessagesPagination(pageSize: pageSize, parameter: paginationParameter)
        self.membersLimit = membersLimit
        self.watchersLimit = watchersLimit
    }

    /// Init a channel query.
    /// - Parameters:
    ///   - channelPayload: a payload that has data needed for channel creation.
    init(channelPayload: ChannelEditDetailPayload<ExtraData>) {
        id = channelPayload.id
        type = channelPayload.type
        self.channelPayload = channelPayload
        pagination = nil
        membersLimit = nil
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
            paginationParameter: channelQuery.pagination?.parameter,
            membersLimit: channelQuery.membersLimit,
            watchersLimit: channelQuery.watchersLimit
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try options.encode(to: encoder)

        // Only needed for channel creation
        try container.encodeIfPresent(channelPayload, forKey: .data)
        
        try pagination.map { try container.encode($0, forKey: .messages) }
        try membersLimit.map { try container.encode(Pagination(pageSize: $0), forKey: .members) }
        try watchersLimit.map { try container.encode(Pagination(pageSize: $0), forKey: .watchers) }
    }
}

extension _ChannelQuery: APIPathConvertible {
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

    /// A channel id
    let channelId: ChannelId
    /// Accept the invite.
    let accept: Bool?
    /// Reject the invite.
    let reject: Bool?
    /// Additional message.
    let message: Message?
}

//
///// An answer for an invite to a channel.
// public struct ChannelInviteResponse: Decodable {
//    /// A channel.
//    let channel: Channel
//    /// Members.
//    let members: [Member]
//    /// Accept the invite.
//    let message: Message?
// }
//
// public struct ChannelUpdate: Encodable {
//    struct ChannelData: Encodable {
//        let channel: Channel
//
//        init(_ channel: Channel) {
//            self.channel = channel
//        }
//
//        func encode(to encoder: Encoder) throws {
//            var container = encoder.container(keyedBy: Channel.EncodingKeys.self)
//            try container.encode(channel.name, forKey: .name)
//            try container.encodeIfPresent(channel.imageURL, forKey: .imageURL)
//            channel.extraData?.encodeSafely(to: encoder, logMessage: "📦 when encoding a channel extra data")
//        }
//    }
//
//    let data: ChannelData
// }
