//
//  UnreadCount.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 25/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

/// An unread counts of the current user.
public struct UnreadCount: Decodable, Hashable {
    public static let noUnread = UnreadCount(channels: 0, messages: 0)
    public internal(set) var channels: Int
    public internal(set) var messages: Int
}

/// An unread counts for a channel.
public struct ChannelUnreadCount: Decodable, Hashable {
    public static let noUnread = ChannelUnreadCount(messages: 0, mentionedMessages: 0)
    public internal(set) var messages: Int
    public internal(set) var mentionedMessages: Int
}
