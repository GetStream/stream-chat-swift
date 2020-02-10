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
    
    /// A message search.
    /// - Parameters:
    ///   - filter: a filter for channels, e.g. `"members".in(["john"])`
    ///   - query: a search query.
    ///   - pagination: a pagination. It works via the standard limit and offset parameters.
    func search(filter: Filter = .none, query: String, pagination: Pagination = .channelsPageSize) -> Observable<[Message]> {
        connectedRequest(request({ [unowned base] completion in
            base.search(filter: filter, query: query, pagination: pagination, completion)
        }))
    }
    
    /// Requests channels with a given query.
    /// - Parameters:
    ///   - filter: a channels filter, e.g. "members".in([User.current])
    ///   - sort: a sorting list for channels.
    ///   - pagination: a channels pagination.
    ///   - messagesLimit: a messages pagination for the each channel.
    ///   - options: a query options (see `QueryOptions`).
    func queryChannels(filter: Filter = .none,
                       sort: [Sorting] = [],
                       pagination: Pagination = .channelsPageSize,
                       messagesLimit: Pagination = .messagesPageSize,
                       options: QueryOptions = []) -> Observable<[ChannelResponse]> {
        connectedRequest(request({ [unowned base] completion in
            base.queryChannels(filter: filter,
                               sort: sort,
                               pagination: pagination,
                               messagesLimit: messagesLimit,
                               options: options,
                               completion)
        }))
    }
}
