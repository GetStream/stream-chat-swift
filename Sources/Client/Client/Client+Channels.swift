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
    
    /// A message search. Creates a `SearchQuery` with given parameters and call `search` with it.
    /// - Parameters:
    ///   - filter: a filter for channels, e.g. `"members".in(["john"])`
    ///   - query: a search query.
    ///   - pagination: a pagination. It works via the standard limit and offset parameters.
    ///   - completion: a completion block with `[Message]`.
    @discardableResult
    func search(filter: Filter,
                query: String,
                pagination: Pagination = [.channelsPageSize],
                _ completion: @escaping Client.Completion<[Message]>) -> Cancellable {
        search(query: SearchQuery(filter: filter, query: query, pagination: pagination), completion)
    }
    
    /// A message search with a given query (see `SearchQuery`).
    /// - Parameters:
    ///   - query: a search query.
    ///   - completion: a completion block with `[Message]`.
    @discardableResult
    func search(query: SearchQuery, _ completion: @escaping Client.Completion<[Message]>) -> Cancellable {
        request(endpoint: .search(query)) { (result: Result<SearchResponse, ClientError>) in
            completion(result.map(to: \.messages).compactMap({ $0["message"] }))
        }
    }
    
    /// Requests channels with given parameters. Creates a `ChannelsQuery` and call the `queryChannels` with it.
    /// - Parameters:
    ///   - filter: a channels filter, e.g. "members".in([User.current])
    ///   - sort: a sorting list for channels.
    ///   - pagination: a channels pagination.
    ///   - messagesLimit: a messages pagination for the each channel.
    ///   - options: a query options (see `QueryOptions`).
    ///   - completion: a completion block with `Client.Completion<[ChannelResponse]`.
    @discardableResult
    func queryChannels(filter: Filter,
                       sort: [Sorting] = [],
                       pagination: Pagination = [.channelsPageSize],
                       messagesLimit: Pagination = [.messagesPageSize],
                       options: QueryOptions = [],
                       _ completion: @escaping Client.Completion<[ChannelResponse]>) -> Cancellable {
        queryChannels(query: .init(filter: filter,
                                   sort: sort,
                                   pagination: pagination,
                                   messagesLimit: messagesLimit,
                                   options: options),
                      completion)
    }
    
    /// Requests channels with a given query (see `ChannelsQuery`).
    /// - Parameters:
    ///   - query: a channels query.
    ///   - completion: a completion block with `Client.Completion<[ChannelResponse]`.
    @discardableResult
    func queryChannels(query: ChannelsQuery, _ completion: @escaping Client.Completion<[ChannelResponse]>) -> Cancellable {
        watchingChannelsAtomic.flush()
        
        return request(endpoint: .channels(query)) { [unowned self] (result: Result<ChannelsResponse, ClientError>) in
            let result = result.map(to: \.channels)
            
            if (query.options.contains(.watch) || query.options.contains(.presence)),
                let channels = result.value?.map({ $0.channel }) {
                channels.forEach { self.watchingChannelsAtomic.add($0, key: $0.cid) }
            }
            
            completion(result)
        }
    }
}
