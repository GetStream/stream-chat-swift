//
//  MutedChannel.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 24/08/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A muted channel.
public struct MutedChannel: Decodable {
    private enum CodingKeys: String, CodingKey {
        case channel
        case created = "created_at"
        case updated = "updated_at"
    }
    
    /// A channel.
    public let channel: Channel
    /// A created date.
    public let created: Date
    /// A updated date.
    public let updated: Date
    
    /// Creates a muted channel.
    /// - Parameters:
    ///   - user: a user.
    ///   - created: a created date.
    ///   - updated: an updated date.
    init(channel: Channel, created: Date, updated: Date) {
        self.channel = channel
        self.created = created
        self.updated = updated
    }
}

/// A response for the muted channel.
public struct MutedChannelResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case currentUser = "own_user"
        case mutedChannel = "channel_mute"
    }
    
    /// An own user.
    public let currentUser: User
    /// A muted channel.
    public let mutedChannel: Channel
}
