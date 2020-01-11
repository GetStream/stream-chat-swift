//
//  Client+Channels.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Channels Requests

public extension Client {
    
    /// A message search.
    /// - Parameters:
    ///   - filter: a filter for channels, e.g. .key("members", .in(["john"]))
    ///   - query: a search query.
    ///   - pagination: a pagination. It works via the standard limit and offset parameters.
    ///   - completion: a completion block with `[Message]`.
    func search(filter: Filter = .none,
                query: String,
                pagination: Pagination = .channelsPageSize,
                _ completion: @escaping ClientCompletion<[Message]>) {
        return rx.search(filter: filter, query: query, pagination: pagination).bindOnce(to: completion)
    }
    
    /// Requests channels with a given query.
    /// - Parameters:
    ///   - query: a channels query (see `ChannelsQuery`).
    ///   - completion: a completion block with `[ChannelResponse]`.
    func channels(query: ChannelsQuery, _ completion: @escaping ClientCompletion<[ChannelResponse]>) {
        return rx.channels(query: query).bindOnce(to: completion)
    }
    
    /// Requests channel with a given query.
    /// - Parameters:
    ///   - query: a channels query (see `ChannelsQuery`).
    ///   - completion: a completion block with `ChannelResponse`.
    func channel(query: ChannelQuery, _ completion: @escaping ClientCompletion<ChannelResponse>) {
        return rx.channel(query: query).bindOnce(to: completion)
    }
    
    /// Get a message by id.
    /// - Parameters:
    ///   - messageId: a message id.
    ///   - completion: a completion block with `MessageResponse`.
    func message(with messageId: String, _ completion: @escaping ClientCompletion<MessageResponse>) {
        return rx.message(with: messageId).bindOnce(to: completion)
    }
    
    /// Mark all messages as readed.
    /// - Parameter completion: an empty completion block.
    func markAllRead(_ completion: @escaping EmptyClientCompletion) {
        return rx.markAllRead().bindOnce(to: completion)
    }
}
