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
    ///   - filter: a filter for channels, e.g. `"members".in(["john"])`
    ///   - query: a search query.
    ///   - pagination: a pagination. It works via the standard limit and offset parameters.
    ///   - completion: a completion block with `[Message]`.
    @discardableResult
    func search(filter: Filter,
                query: String,
                pagination: Pagination = .channelsPageSize,
                _ completion: @escaping Client.Completion<[Message]>) -> URLSessionTask {
        let query = SearchQuery(filter: filter, query: query, pagination: pagination)
        return request(endpoint: .search(query)) { (result: Result<SearchResponse, ClientError>) in
            completion(result.map({ $0.messages.compactMap({ $0["message"] }) }))
        }
    }
    
    /// Requests channels with a given query.
    /// - Parameters:
    ///   - filter: a channels filter, e.g. "members".in([User.current])
    ///   - sort: a sorting list for channels.
    ///   - pagination: a channels pagination.
    ///   - messagesLimit: a messages pagination for the each channel.
    ///   - options: a query options (see `QueryOptions`).
    ///   - completion: a completion block with `Client.Completion<[ChannelResponse]`.
    @discardableResult
    func queryChannels(filter: Filter = .none,
                       sort: [Sorting] = [],
                       pagination: Pagination = .channelsPageSize,
                       messagesLimit: Pagination = .messagesPageSize,
                       options: QueryOptions = [],
                       _ completion: @escaping Client.Completion<[ChannelResponse]>) -> URLSessionTask {
        let query = ChannelsQuery(filter: filter,
                                  sort: sort,
                                  pagination: pagination,
                                  messagesLimit: messagesLimit,
                                  options: options)
        
        return request(endpoint: .channels(query)) { (result: Result<ChannelsResponse, ClientError>) in
            completion(result.map({ $0.channels }))
        }
    }
}
