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

extension ChannelsPresenter {
    fileprivate static var rxChangesKey: UInt8 = 0
}

public extension Reactive where Base == ChannelsPresenter {
    
    // MARK: Changes
    
    /// An observable view changes (see `ViewChanges`).
    var changes: Driver<ViewChanges> {
        associated(to: base, key: &ChannelsPresenter.rxChangesKey) { [weak base] in
            Driver.merge(parsedChannelResponses(channelsRequest),
                         events,
                         connectionErrors,
                         (base?.actions ?? .empty()).asDriver(onErrorJustReturn: .none))
                .do(onDispose: { base?.disposeBagForInternalRequests = DisposeBag() })
        }
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
            .do(onNext: { [weak base] _ in base?.rx.removeFromItems(channelPresenter) })
            .asDriver(onErrorJustReturn: .empty)
    }
}

private extension Reactive where Base == ChannelsPresenter {
    
    func parsedChannelResponses(_ channelResponses: Observable<[ChannelResponse]>) -> Driver<ViewChanges> {
        channelResponses
            .map { [weak base] in base?.parseChannels($0) ?? .none }
            .filter { $0 != .none }
            .asClientDriver()
    }
    
    var channelsRequest: Observable<[ChannelResponse]> {
        prepareRequest(startPaginationWith: base.pageSize)
            .compactMap { [weak base] in base?.rx.channelsQuery(pagination: $0) }
            .flatMapLatest { Client.shared.rx.queryChannels(query: $0).retry(3) }
    }
    
    var events: Driver<ViewChanges> {
        Client.shared.rx.events()
            .filter({ [weak base] event in
                if let eventsFilter = base?.eventsFilter {
                    return eventsFilter(event, nil)
                }
                
                return true
            })
            .flatMap { [weak base] in base?.parse(event: $0) ?? Observable.just(.none) }
            .filter { $0 != .none }
            .asClientDriver()
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
            base.next = [.channelsNextPageSize, .offset((base.next.offset ?? 0) - 1)]
        }
        
        base.items.remove(at: index)
        base.actions.onNext(.itemRemoved(index, base.items))
    }
}
