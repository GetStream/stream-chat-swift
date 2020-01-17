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
    @discardableResult
    func search(filter: Filter,
                query: String,
                pagination: Pagination = .channelsPageSize,
                _ completion: @escaping Client.Completion<[Message]>) -> URLSessionTask {
        if query.isBlank {
            completion(.failure(.channelsSearchQueryEmpty))
            return .empty
        }
        
        if case .none = filter {
            completion(.failure(.channelsSearchFilterEmpty))
            return .empty
        }
        
        let query = SearchQuery(filter: filter, query: query, pagination: pagination)
        
        return request(endpoint: .search(query)) { (result: Result<SearchResponse, ClientError>) in
            completion(result.map({ $0.messages.compactMap({ $0["message"] }) }))
        }
    }
    
    /// Requests channels with a given query.
    /// - Parameters:
    ///   - query: a channels query (see `ChannelsQuery`).
    ///   - completion: a completion block with `[ChannelResponse]`.
    @discardableResult
    func channels(query: ChannelsQuery, _ completion: @escaping Client.Completion<[ChannelResponse]>) -> URLSessionTask {
        return request(endpoint: .channels(query)) { (result: Result<ChannelsResponse, ClientError>) in
            completion(result.map({ $0.channels }))
        }
    }
    
    /// Requests channel with a given query.
    /// - Parameters:
    ///   - query: a channels query (see `ChannelsQuery`).
    ///   - completion: a completion block with `ChannelResponse`.
    @discardableResult
    func channel(query: ChannelQuery, _ completion: @escaping Client.Completion<ChannelResponse>) -> URLSessionTask {
        return request(endpoint: .channel(query), completion)
    }

    /// Get a message by id.
    /// - Parameters:
    ///   - messageId: a message id.
    ///   - completion: a completion block with `MessageResponse`.
    @discardableResult
    func message(with messageId: String, _ completion: @escaping Client.Completion<MessageResponse>) -> URLSessionTask {
        return request(endpoint: .message(messageId), completion)
    }

    /// Mark all messages as readed.
    /// - Parameter completion: an empty completion block.
    @discardableResult
    func markAllRead(_ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        return request(endpoint: .markAllRead, completion)
    }
}
