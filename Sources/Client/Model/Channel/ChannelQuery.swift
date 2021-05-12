//
//  ChannelQuery.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A channel query.
public struct ChannelQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case data
        case messages
        case members
        case watchers
    }
    
    /// A channel.
    public let channel: Channel
    /// A pagination for messages (see `Pagination`).
    public let messagesPagination: Pagination
    /// A pagination for members (see `Pagination`). You can use `.limit` and `.offset`.
    public let membersPagination: Pagination
    /// A pagination for watchers (see `Pagination`). You can use `.limit` and `.offset`.
    public let watchersPagination: Pagination
    /// A query options.
    public let options: QueryOptions
    
    /// Init a channel query.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - memebers: members of the channel.
    ///   - messagesPagination: a pagination for messages.
    ///   - membersPagination: a pagination for members. You can use `.limit` and `.offset`.
    ///   - watchersPagination: a pagination for watchers. You can use `.limit` and `.offset`.
    ///   - options: a query options (see `QueryOptions`).
    public init(channel: Channel,
                messagesPagination: Pagination = [],
                membersPagination: Pagination = [],
                watchersPagination: Pagination = [],
                options: QueryOptions = []) {
        self.channel = channel
        self.messagesPagination = messagesPagination
        self.membersPagination = membersPagination
        self.watchersPagination = watchersPagination
        self.options = options
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try options.encode(to: encoder)
        
        // The channel data only needs for creating it.
        if !channel.didLoad, !channel.isEmpty {
            try container.encode(channel, forKey: .data)
        }
        
        if !messagesPagination.isEmpty {
            try container.encode(messagesPagination, forKey: .messages)
        }
        
        if !membersPagination.isEmpty {
            try container.encode(membersPagination, forKey: .members)
        }
        
        if !watchersPagination.isEmpty {
            try container.encode(watchersPagination, forKey: .watchers)
        }
    }
}

/// An answer for an invite to a channel.
public struct ChannelInviteAnswer: Encodable {
    private enum CodingKeys: String, CodingKey {
        case accept = "accept_invite"
        case reject = "reject_invite"
        case message
    }
    
    /// A channel.
    let channel: Channel
    /// Accept the invite.
    let accept: Bool?
    /// Reject the invite.
    let reject: Bool?
    /// Additional message.
    let message: Message?
}

/// An answer for an invite to a channel.
public struct ChannelInviteResponse: Decodable {
    /// A channel.
    let channel: Channel
    /// Members.
    let members: [Member]
    /// Accept the invite.
    let message: Message?
}

public struct ChannelUpdate: Encodable {
    struct ChannelData: Encodable {
        let channel: Channel
        
        init(_ channel: Channel) {
            self.channel = channel
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: Channel.EncodingKeys.self)
            channel.extraData?.encodeSafely(to: encoder, logMessage: "📦 when encoding a channel extra data")
        }
    }
    
    let data: ChannelData
}

public struct MembersQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case sort
        case limit
        case offset
        case id
        case type
        case members
    }
    
    /// Filter conditions.
    public let filter: Filter
    /// Sort options, e.g. `[.init("last_active", isAscending: false)]`
    public let sort: [Sorting]
    /// Used for paginating response.
    public let limit: Int
    /// Offset of pagination.
    public let offset: Int
    /// Channel type this query will belong to.
    public let channelType: ChannelType
    /// Channel's unique id this query belongs to.
    public let id: String?
    /// Channel members for the query.
    /// This is only used if the channel id is generated from backend.
    public let members: [Member]?
    
    public init(channelId: ChannelId,
                filter: Filter,
                sorting: [Sorting],
                limit: Int = 100,
                offset: Int = 0) {
        self.channelType = channelId.type
        self.id = channelId.id
        self.members = nil
        self.filter = filter
        self.sort = sorting
        self.limit = limit
        self.offset = offset
    }
    
    public init(channelType: ChannelType,
                members: [Member],
                filter: Filter,
                sorting: [Sorting],
                limit: Int = 100,
                offset: Int = 0) {
        self.channelType = channelType
        self.id = nil
        self.members = members
        self.filter = filter
        self.sort = sorting
        self.limit = limit
        self.offset = offset
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(filter, forKey: .filter)
        try container.encode(limit, forKey: .limit)
        try container.encode(offset, forKey: .offset)
        
        if !sort.isEmpty {
            try container.encode(sort, forKey: .sort)
        }
        
        try container.encode(channelType, forKey: .type)
        
        if let id = id {
            try container.encode(id, forKey: .id)
        } else if let members = members {
            try container.encode(members, forKey: .members)
        }
    }
}
