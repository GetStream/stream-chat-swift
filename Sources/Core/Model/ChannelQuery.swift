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
    }
    
    /// A channel.
    public let channel: Channel
    /// Members of the channel (see `Member`).
    public let members: [Member]
    /// A query options.
    public let options: QueryOptions
    /// A pagination (see `Pagination`).
    public let pagination: Pagination
    
    /// Init a channel query.
    ///
    /// - Parameters:
    ///     - channel: a channel.
    ///     - memebers: members of the channel.
    ///     - pagination: a pagination (see `Pagination`).
    public init(channel: Channel, members: [Member], pagination: Pagination, options: QueryOptions) {
        self.channel = channel
        self.members = members
        self.pagination = pagination
        self.options = options
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try options.encode(to: encoder)
        channel.members = members
        try container.encode(channel, forKey: .data)
        try container.encode(pagination, forKey: .messages)
    }
}
