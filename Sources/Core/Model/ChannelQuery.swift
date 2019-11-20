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
    public let members: Set<Member>
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
    public init(channel: Channel, members: Set<Member>, pagination: Pagination, options: QueryOptions) {
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
            try container.encode(channel.name, forKey: .name)
            try container.encodeIfPresent(channel.imageURL, forKey: .imageURL)
            channel.extraData?.encodeSafely(to: encoder, logMessage: "📦 when encoding a channel extra data")
        }
    }
    
    let data: ChannelData
}
