//
//  Client+RxChannels.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

// MARK: Channels Requests

public extension Reactive where Base == Client {
    
    /// A message search. Creates a `SearchQuery` with given parameters and call `search` with it.
    /// - Parameters:
    ///   - filter: a filter for channels, e.g. `"members".in(["john"])`
    ///   - query: a search query.
    ///   - pagination: a pagination. It works via the standard limit and offset parameters.
    func search(filter: Filter, query: String, pagination: Pagination = [.channelsPageSize]) -> Observable<[Message]> {
        search(query: .init(filter: filter, query: query, pagination: pagination))
    }
    
    /// A message search with a given query (see `SearchQuery`).
    /// - Parameter query: a search query.
    ///   - filter: a filter for channels, e.g. `"members".in(["john"])`
    func search(query: SearchQuery) -> Observable<[Message]> {
        connected(request({ [unowned base] completion in
            base.search(query: query, completion)
        }))
    }
    
    /// Requests channels with given parameters. Creates a `ChannelsQuery` and call the `queryChannels` with it.
    /// - Parameters:
    ///   - filter: a channels filter, e.g. "members".in([User.current])
    ///   - sort: a sorting list for channels.
    ///   - pagination: a channels pagination.
    ///   - messagesLimit: a messages pagination for the each channel.
    ///   - options: a query options (see `QueryOptions`).
    func queryChannels(filter: Filter,
                       sort: [Sorting] = [],
                       pagination: Pagination = [.channelsPageSize],
                       messagesLimit: Pagination = [.messagesPageSize],
                       options: QueryOptions = []) -> Observable<[ChannelResponse]> {
        connected(request({ [unowned base] completion in
            base.queryChannels(filter: filter,
                               sort: sort,
                               pagination: pagination,
                               messagesLimit: messagesLimit,
                               options: options,
                               completion)
        }))
    }
    
    /// Requests channels with a given query (see `ChannelsQuery`).
    /// - Parameter query: a channels query.
    func queryChannels(query: ChannelsQuery) -> Observable<[ChannelResponse]> {
        connected(request({ [unowned base] completion in
            base.queryChannels(query: query, completion)
        }))
    }
}
