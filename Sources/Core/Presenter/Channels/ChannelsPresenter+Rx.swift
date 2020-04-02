//
//  ChannelsPresenter+Rx.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 13/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift
import RxCocoa

public extension Reactive where Base == ChannelsPresenter {
    
    // MARK: Changes
    
    /// An observable view changes (see `ViewChanges`).
    var changes: Driver<ViewChanges> {
        base.rxChanges
    }
    
    internal func setupChanges() -> Driver<ViewChanges> {
        Driver.merge(parsedChannelResponses(channelsRequest),
                     // parsedChannelResponses(channelsDatabaseFetch),
            events,
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
    func hide(_ channelPresenter: ChannelPresenter, clearHistory: Bool = false) -> Driver<EmptyData> {
        channelPresenter.channel.rx
            .hide(clearHistory: clearHistory)
            .do(onNext: { _ in self.removeFromItems(channelPresenter) })
            .asDriver(onErrorJustReturn: .empty)
    }
}

private extension Reactive where Base == ChannelsPresenter {
    
    func parsedChannelResponses(_ channelResponses: Observable<[ChannelResponse]>) -> Driver<ViewChanges> {
        channelResponses
            .map { [weak base] in base?.parseChannels($0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError($0))) }
    }
    
    var channelsRequest: Observable<[ChannelResponse]> {
        prepareRequest(startPaginationWith: base.pageSize)
            .compactMap { self.channelsQuery(pagination: $0) }
            .flatMapLatest { Client.shared.rx.queryChannels(query: $0).retry(3) }
    }
    
    //    var channelsDatabaseFetch: Observable<[ChannelResponse]> {
    //        return prepareDatabaseFetch(startPaginationWith: base.pageSize)
    //            .compactMap { self.channelsQuery(pagination: $0) }
    //            .observeOn(SerialDispatchQueueScheduler.init(qos: .userInitiated))
    //            .flatMapLatest { Client.shared.fetchChannels($0) }
    //    }
    
    var events: Driver<ViewChanges> {
        Client.shared.rx.onEvent()
            .filter({ [weak base] event in
                if let eventsFilter = base?.eventsFilter {
                    return eventsFilter(event, nil)
                }
                
                return true
            })
            .map { [weak base] in base?.parse(event: $0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError($0))) }
    }
    
    func channelsQuery(pagination: Pagination) -> ChannelsQuery {
        ChannelsQuery(filter: base.filter,
                      sort: base.sorting,
                      pagination: pagination,
                      options: base.queryOptions)
    }
    
    func removeFromItems(_ channelPresenter: ChannelPresenter) {
        guard let index = base.items.firstIndex(where: channelPresenter.channel.cid) else {
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
