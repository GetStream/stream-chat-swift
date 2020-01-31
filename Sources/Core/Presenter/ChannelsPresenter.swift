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
    
    /// A filter for channels events.
    public var eventsFilter: Event.Filter?
    
    /// A filter for a selected channel events.
    /// When a user select a channel, then `ChannelsViewController` create a `ChatViewController`
    /// with a selected channel presenter and this channel events filter.
    public var channelEventsFilter: Event.Filter?
    
    /// An observable view changes (see `ViewChanges`).
    public private(set) lazy var changes = Driver.merge(parsedChannelResponses(channelsRequest),
                                                        parsedChannelResponses(channelsDatabaseFetch),
                                                        webSocketEvents,
                                                        actions.asDriver(onErrorJustReturn: .none),
                                                        connectionErrors)
        .do(onDispose: { [weak self] in self?.disposeBagForInternalRequests = DisposeBag() })
    
    private lazy var channelsRequest: Observable<[ChannelResponse]> = prepareRequest(startPaginationWith: pageSize)
        .compactMap { [weak self] in self?.channelsQuery(pagination: $0) }
        .flatMapLatest { Client.shared.channels(query: $0).retry(3) }
    
    private lazy var channelsDatabaseFetch: Observable<[ChannelResponse]> = prepareDatabaseFetch(startPaginationWith: pageSize)
        .compactMap { [weak self] in self?.channelsQuery(pagination: $0) }
        .observeOn(SerialDispatchQueueScheduler(qos: .userInitiated))
        .flatMapLatest { Client.shared.fetchChannels($0) }
    
    private lazy var webSocketEvents: Driver<ViewChanges> = Client.shared.webSocket.response
        .filter({ [weak self] response in
            if let eventsFilter = self?.eventsFilter {
                return eventsFilter(response.event, nil)
            }
            
            return true
        })
        .map { [weak self] in self?.parseEvents(response: $0) ?? .none }
        .filter { $0 != .none }
        .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    
    private let actions = PublishSubject<ViewChanges>()
    private var disposeBagForInternalRequests = DisposeBag()
    
    /// Init a channels presenter.
    ///
    /// - Parameters:
    ///   - filter: a channel filter.
    ///   - sorting: a channel sorting. By default channels will be sorted by the last message date.
    ///   - queryOptions: query options (see `QueryOptions`).
    ///   - showChannelStatuses: show channel statuses on a chat view controller of a selected channel.
    public init(filter: Filter = .none,
                sorting: [Sorting] = [],
                queryOptions: QueryOptions = .all,
                showChannelStatuses: Bool = true) {
        self.queryOptions = queryOptions
        self.showChannelStatuses = showChannelStatuses
        self.filter = filter
        self.sorting = sorting
        super.init(pageSize: .channelsPageSize)
    }
    
    private func channelsQuery(pagination: Pagination) -> ChannelsQuery {
        return ChannelsQuery(filter: filter, sort: sorting, pagination: pagination, options: queryOptions)
    }
}

// MARK: - Actions

public extension ChannelsPresenter {
    
    /// Hide a channel and remove a channel presenter from items.
    ///
    /// - Parameters:
    ///   - channelPresenter: a channel presenter.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    func hide(_ channelPresenter: ChannelPresenter, clearHistory: Bool = false) -> Driver<Void> {
        return channelPresenter.channel
            .hide(for: User.current, clearHistory: clearHistory)
            .void()
            .do(onNext: { [weak self] in self?.removeFromItems(channelPresenter) })
            .asDriver(onErrorJustReturn: ())
    }
    
    private func removeFromItems(_ channelPresenter: ChannelPresenter) {
        guard let index = items.firstIndex(whereChannelId: channelPresenter.channel.id,
                                           channelType: channelPresenter.channel.type) else {
            return
        }
        
        // Update pagination offset.
        if next != pageSize {
            next = .channelsNextPageSize + .offset(next.offset - 1)
        }
        
        items.remove(at: index)
        actions.onNext(.itemRemoved(index, items))
    }
}

// MARK: - Response Parsing

extension ChannelsPresenter {
    
    private func parsedChannelResponses(_ channelResponses: Observable<[ChannelResponse]>) -> Driver<ViewChanges> {
        return channelResponses
            .map { [weak self] in self?.parseChannels($0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
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
}

// MARK: - WebSocket Events Parsing

extension ChannelsPresenter {
    private func parseEvents(response: WebSocket.Response) -> ViewChanges {
        guard let cid = response.cid else {
            return parseNotifications(response: response)
        }
        
        switch response.event {
        case .channelUpdated(let channelResponse, _):
            if let index = items.firstIndex(where: channelResponse.channel.cid),
                let channelPresenter = items[index].channelPresenter {
                channelPresenter.parseEvents(event: response.event)
                return .itemsUpdated([index], [], items)
            }
            
        case .channelDeleted:
            if let index = items.firstIndex(where: cid) {
                items.remove(at: index)
                return .itemRemoved(index, items)
            }
            
        case .channelHidden:
            if let index = items.firstIndex(where: cid) {
                items.remove(at: index)
                return .itemRemoved(index, items)
            }
            
        case .messageNew(_, _, _, let channel, _):
            return parseNewMessage(response: response, from: channel)
            
        case .messageDeleted(let message, _):
            if let index = items.firstIndex(where: cid),
                let channelPresenter = items[index].channelPresenter {
                channelPresenter.parseEvents(event: response.event)
                return .itemsUpdated([index], [message], items)
            }
            
        case .messageRead:
            if let index = items.firstIndex(where: cid) {
                return .itemsUpdated([index], [], items)
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
                let index = items.firstIndex(whereChannelId: channel.id, channelType: channel.type),
                let channelPresenter = items[index].channelPresenter {
                channelPresenter.unreadMessageReadAtomic.set(nil)
                return .itemsUpdated([index], [], items)
            }
        default:
            break
        }
        
        return .none
    }
    
    private func parseNewMessage(response: WebSocket.Response, from channel: Channel?) -> ViewChanges {
        if let cid = response.cid,
            let index = items.firstIndex(where: cid),
            let channelPresenter = items.remove(at: index).channelPresenter {
            channelPresenter.parseEvents(event: response.event)
            items.insert(.channelPresenter(channelPresenter), at: 0)
            
            if index == 0 {
                return .itemsUpdated([0], [], items)
            }
            
            return .itemMoved(fromRow: index, toRow: 0, items)
        }
        
        if let channel = channel {
            return parseNewChannel(channel: channel)
        }
        
        return .none
    }
    
    private func parseNewChannel(channel: Channel) -> ViewChanges {
        guard items.firstIndex(whereChannelId: channel.id, channelType: channel.type) == nil else {
            return .none
        }
        
        let channelPresenter = ChannelPresenter(channel: channel, queryOptions: queryOptions, showStatuses: showChannelStatuses)
        // We need to load messages for new channel.
        loadChannelMessages(channelPresenter)
        items.insert(.channelPresenter(channelPresenter), at: 0)
        
        // Update pagination offset.
        if next != pageSize {
            next = .channelsNextPageSize + .offset(next.offset + 1)
        }
        
        return .itemsAdded([0], nil, false, items)
    }
    
    private func loadChannelMessages(_ channelPresenter: ChannelPresenter) {
        channelPresenter.parsedMessagesRequest.asObservable()
            .take(1)
            .subscribe(onNext: { [weak self, weak channelPresenter] _ in
                guard let self = self,
                    let channelPresenter = channelPresenter,
                    let index = self.items.firstIndex(whereChannelId: channelPresenter.channel.id,
                                                      channelType: channelPresenter.channel.type) else {
                    return
                }
                
                self.actions.onNext(.itemsUpdated([index], [], self.items))
            })
            .disposed(by: disposeBagForInternalRequests)
    }
}
