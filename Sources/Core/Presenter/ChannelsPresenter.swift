//
//  ChannelsPresenter.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

/// A channels presenter.
public final class ChannelsPresenter: Presenter<ChatItem> {
    /// A callback type to provide an extra data for a channel.
    public typealias ChannelMessageExtraDataCallback = (_ channel: Channel) -> ChannelPresenter.MessageExtraDataCallback?
    
    /// A channel type.
    public let channelType: ChannelType
    /// Query options.
    public let queryOptions: QueryOptions
    /// Show channel statuses in a selected chat view controller.
    public let showChannelStatuses: Bool
    
    /// Filter channels.
    ///
    /// For example, in your channels view controller:
    /// ```
    /// if let currentUser = User.current {
    ///     channelPresenter = .init(channelType: .messaging,
    ///                              filter: .key("members", .in([currentUser.id])))
    /// }
    /// ```
    public let filter: Filter
        
    /// Sort channels.
    ///
    /// By default channels will be sorted by the last message date.
    public let sorting: [Sorting]
    
    /// A callback to provide an extra data for a channel.
    public var channelMessageExtraDataCallback: ChannelMessageExtraDataCallback?
    
    /// An observable view changes (see `ViewChanges`).
    public private(set) lazy var changes = Driver.merge(requestChannels, webSocketEvents, connectionErrors)
    
    private lazy var requestChannels: Driver<ViewChanges> = prepareRequest(startPaginationWith: pageSize)
        .map { [weak self] in self?.channelsQuery(pagination: $0) }
        .unwrap()
        .flatMapLatest { Client.shared.channels(query: $0).retry(3) }
        .map { [weak self] in self?.parseChannels($0) ?? .none }
        .filter { $0 != .none }
        .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    
    private lazy var webSocketEvents: Driver<ViewChanges> = Client.shared.webSocket.response
        .map { [weak self] in self?.parseEvents(response: $0) ?? .none }
        .filter { $0 != .none }
        .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    
    /// Init a channels presenter.
    ///
    /// - Parameters:
    ///   - channelType: a channel type.
    ///   - filter: a channel filter.
    ///   - sorting: a channel sorting. By default channels will be sorted by the last message date.
    ///   - queryOptions: query options (see `QueryOptions`).
    ///   - showChannelStatuses: show channel statuses on a chat view controller of a selected channel.
    public init(channelType: ChannelType,
                filter: Filter = .none,
                sorting: [Sorting] = [],
                queryOptions: QueryOptions = .all,
                showChannelStatuses: Bool = true) {
        self.channelType = channelType
        self.queryOptions = queryOptions
        self.showChannelStatuses = showChannelStatuses
        self.filter = filter
        self.sorting = sorting
        super.init(pageSize: .channelsPageSize)
    }
}

// MARK: - Parsing

extension ChannelsPresenter {
    
    private func channelsQuery(pagination: Pagination) -> ChannelsQuery {
        return ChannelsQuery(filter: filter, sort: sorting, pagination: pagination, options: queryOptions)
    }
    
    private func parseChannels(_ channels: [ChannelResponse]) -> ViewChanges {
        let isNextPage = next != pageSize
        var items = isNextPage ? self.items : [ChatItem]()
        
        if let last = items.last, case .loading = last {
            items.removeLast()
        }
        
        let row = items.count
        
        items.append(contentsOf: channels.map {
            let channelPresenter = ChannelPresenter(response: $0, queryOptions: queryOptions, showStatuses: showChannelStatuses)
            
            if let channelMessageExtraDataCallback = self.channelMessageExtraDataCallback {
                channelPresenter.messageExtraDataCallback = channelMessageExtraDataCallback($0.channel)
            }
            
            return .channelPresenter(channelPresenter)
        })
        
        if channels.count == next.limit {
            next = .channelsNextPageSize + .offset(next.offset + next.limit)
            items.append(.loading(false))
        } else {
            next = pageSize
        }
        
        self.items = items
        
        return isNextPage ? .reloaded(row, items) : .reloaded(0, items)
    }
    
    private func parseEvents(response: WebSocket.Response) -> ViewChanges {
        guard let channelId = response.channelId else {
            return parseNotifications(response: response)
        }
        
        switch response.event {
        case .channelDeleted:
            if let index = items.firstIndex(whereChannelId: channelId) {
                items.remove(at: index)
                return .itemRemoved(index, items)
            }
        case .messageNew(_, _, _, let channel, _):
            return parseNewMessage(response: response, from: channel)
        case .messageDeleted(let message, _):
            if let index = items.firstIndex(whereChannelId: channelId),
                let channelPresenter = items[index].channelPresenter {
                channelPresenter.parseEvents(event: response.event)
                return .itemUpdated([index], [message], items)
            }
        default:
            break
        }
        
        return .none
    }
    
    private func parseNotifications(response: WebSocket.Response) -> ViewChanges {
        switch response.event {
        case .notificationAddedToChannel(let channel, _):
            return parseNewChannel(channel: channel)
        case .notificationMarkRead(let channel, let unreadCount, _, _):
            if unreadCount == 0,
                let channel = channel,
                let index = items.firstIndex(whereChannelId: channel.id),
                let channelPresenter = items[index].channelPresenter {
                channelPresenter.unreadMessageReadAtomic.set(nil)
                return .itemUpdated([index], [], items)
            }
        default:
            break
        }
        
        return .none
    }
    
    private func parseNewMessage(response: WebSocket.Response, from channel: Channel?) -> ViewChanges {
        if let channelId = response.channelId,
            let index = items.firstIndex(whereChannelId: channelId),
            let channelPresenter = items.remove(at: index).channelPresenter {
            channelPresenter.parseEvents(event: response.event)
            items.insert(.channelPresenter(channelPresenter), at: 0)
            
            return .itemMoved(fromRow: index, toRow: 0, items)
        }
        
        if let channel = channel {
            return parseNewChannel(channel: channel)
        }
        
        return .none
    }
    
    private func parseNewChannel(channel: Channel) -> ViewChanges {
        guard items.firstIndex(whereChannelId: channel.id) == nil else {
            return .none
        }
        
        let channelPresenter = ChannelPresenter(channel: channel, queryOptions: queryOptions, showStatuses: showChannelStatuses)
        // We need to load messages and for that we have to subscribe for changes in ChannelsViewController.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak channelPresenter] in channelPresenter?.reload() }
        items.insert(.channelPresenter(channelPresenter), at: 0)
        
        // Update pagination offset.
        if next != pageSize {
            next = .channelsNextPageSize + .offset(next.offset + 1)
        }
        
        return .itemAdded(0, nil, false, items)
    }
}
