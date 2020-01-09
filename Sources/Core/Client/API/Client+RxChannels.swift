//
//  Client+RxChannels.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: Channels Requests

public extension Reactive where Base == Client {
    
    /// A message search.
    /// - Parameters:
    ///   - filter: a filter for channels, e.g. .key("members", .in(["john"]))
    ///   - query: a search query.
    ///   - pagination: a pagination. It works via the standard limit and offset parameters.
    func search(filter: Filter = .none, query: String, pagination: Pagination = .channelsPageSize) -> Observable<[Message]> {
        if query.isBlank {
            return .empty()
        }
        
        let query = SearchQuery(filter: filter, query: query, pagination: pagination)
        
        if case .none = query.filter {
            return .error(SearchQueryError.emptyFilter)
        }
        
        let searchRequest: Observable<SearchResponse> = request(endpoint: .search(query))
        
        return base.connectedRequest(searchRequest.map { $0.messages.compactMap({ $0["message"] }) })
    }
    
    /// Requests channels with a given query.
    ///
    /// - Parameter query: a channels query (see `ChannelsQuery`).
    /// - Returns: a list of a channel response (see `ChannelResponse`).
    func channels(query: ChannelsQuery) -> Observable<[ChannelResponse]> {
        let channelsRequest: Observable<ChannelsResponse> = request(endpoint: .channels(query))
        return base.connectedRequest(channelsRequest.map { $0.channels })
            .do(onNext: { [unowned base] in base.add(channelsToDatabase: $0, query: query) })
    }
    
    /// Requests channel with a given query.
    ///
    /// - Parameter query: a channels query (see `ChannelsQuery`).
    /// - Returns: a list of a channel response (see `ChannelResponse`).
    func channel(query: ChannelQuery) -> Observable<ChannelResponse> {
        return base.connectedRequest(.channel(query))
            .do(onNext: { channelResponse in
                if query.options.contains(.state) {
                    channelResponse.channel.add(messagesToDatabase: channelResponse.messages)
                }
            })
    }
    
    /// Get a message by id.
    /// - Parameter messageId: a message id.
    func message(with messageId: String) -> Observable<MessageResponse> {
        return base.connectedRequest(.message(messageId))
    }
    
    /// Mark all messages as readed.
    func markAllRead() -> Observable<Void> {
        let markAllReadRequest: Observable<EmptyData> = request(endpoint: .markAllRead)
        return base.connectedRequest(markAllReadRequest.map({ _ in Void() }))
    }
}
