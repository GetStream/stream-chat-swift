//
//  ChannelsPresenter+Rx.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 13/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public extension Reactive where Base == ChannelsPresenter {
    
    // MARK: Changes
    
    /// An observable view changes (see `ViewChanges`).
    var changes: Driver<ViewChanges> {
        return base.rxChanges
    }
    
    internal func setupChanges() -> Driver<ViewChanges> {
        return Driver.merge(parsedChannelResponses(channelsRequest),
                            parsedChannelResponses(channelsDatabaseFetch),
                            webSocketEvents,
                            connectionErrors,
                            base.actions.asDriver(onErrorJustReturn: .none))
            .do(onDispose: { [weak base] in base?.disposeBagForInternalRequests = DisposeBag() })
    }
    
    // MARK: Actions
    
    /// Hide a channel and remove a channel presenter from items.
    ///
    /// - Parameters:
    ///   - channelPresenter: a channel presenter.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    func hide(_ channelPresenter: ChannelPresenter, clearHistory: Bool = false) -> Driver<Void> {
        return channelPresenter.channel.rx
            .hide(for: User.current, clearHistory: clearHistory)
            .void()
            .do(onNext: { self.removeFromItems(channelPresenter) })
            .asDriver(onErrorJustReturn: ())
    }
}

private extension Reactive where Base == ChannelsPresenter {
    
    func parsedChannelResponses(_ channelResponses: Observable<[ChannelResponse]>) -> Driver<ViewChanges> {
        return channelResponses
            .map { [weak base] in base?.parseChannels($0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    }
    
    var channelsRequest: Observable<[ChannelResponse]> {
        return prepareRequest(startPaginationWith: base.pageSize)
            .compactMap { self.channelsQuery(pagination: $0) }
            .flatMapLatest { Client.shared.rx.channels(query: $0).retry(3) }
    }
    
    var channelsDatabaseFetch: Observable<[ChannelResponse]> {
        return prepareDatabaseFetch(startPaginationWith: base.pageSize)
            .compactMap { self.channelsQuery(pagination: $0) }
            .observeOn(SerialDispatchQueueScheduler.init(qos: .userInitiated))
            .flatMapLatest { Client.shared.fetchChannels($0) }
    }
    
    var webSocketEvents: Driver<ViewChanges> {
        return Client.shared.webSocket.rx.response
            .filter({ [weak base] response in
                if let eventsFilter = base?.eventsFilter {
                    return eventsFilter(response.event, nil)
                }
                
                return true
            })
            .map { [weak base] in base?.parseEvents(response: $0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    }
    
    func channelsQuery(pagination: Pagination) -> ChannelsQuery {
        return ChannelsQuery(filter: base.filter,
                             sort: base.sorting,
                             pagination: pagination,
                             options: base.queryOptions)
    }
    
    func removeFromItems(_ channelPresenter: ChannelPresenter) {
        guard let index = base.items.firstIndex(whereChannelId: channelPresenter.channel.id,
                                                channelType: channelPresenter.channel.type) else {
                                                    return
        }
        
        // Update pagination offset.
        if base.next != base.pageSize {
            base.next = .channelsNextPageSize + .offset(base.next.offset - 1)
        }
        
        base.items.remove(at: index)
        base.actions.onNext(.itemRemoved(index, base.items))
    }
}
