//
//  ChannelsPresenter.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift
import RxCocoa

/// A channels presenter.
public final class ChannelsPresenter: Presenter {
    /// A callback type to provide an extra setup for a channel presenter.
    public typealias OnChannelPresenterSetup = (ChannelPresenter) -> Void
    
    /// Query options.
    public let queryOptions: QueryOptions
    
    /// Filter channels.
    ///
    /// For example, in your channels view controller:
    /// ```
    /// if let currentUser = User.current {
    ///     presenter = .init(channelType: .messaging, filter: "members".in([currentUser.id]))
    /// }
    /// ```
    public let filter: Filter
    
    /// Sort channels.
    ///
    /// By default channels will be sorted by the last message date.
    public let sorting: [Sorting]
    
    /// A callback to provide an extra setup for a channel presenter.
    public var onChannelPresenterSetup: OnChannelPresenterSetup?
    
    /// A filter for channels events.
    public var eventsFilter: StreamChatClient.Event.Filter?
    
    /// A filter for a selected channel events.
    /// When a user select a channel, then `ChannelsViewController` create a `ChatViewController`
    /// with a selected channel presenter and this channel events filter.
    public var channelEventsFilter: StreamChatClient.Event.Filter?
    
    /// It will trigger `channel.stopWatching()` for each channel, if needed when the presenter was deallocated.
    /// It's no needed if you will disconnect when the presenter will be deallocated.
    public var stopChannelsWatchingIfNeeded = false
    
    let actions = PublishSubject<ViewChanges>()
    var disposeBagForInternalRequests = DisposeBag()
    
    /// Init a channels presenter.
    ///
    /// - Parameters:
    ///   - filter: a channel filter.
    ///   - sorting: a channel sorting. By default channels will be sorted by the last message date.
    ///   - queryOptions: query options (see `QueryOptions`).
    public init(filter: Filter,
                sorting: [Sorting] = [],
                queryOptions: QueryOptions = .all) {
        self.queryOptions = queryOptions
        self.filter = filter
        self.sorting = sorting
        super.init(pageSize: [.channelsPageSize])
    }
}

// MARK: - API

public extension ChannelsPresenter {
    
    /// View changes (see `ViewChanges`).
    func changes(_ onNext: @escaping Client.Completion<ViewChanges>) -> AutoCancellable {
        rx.changes.asObservable().bind(to: onNext)
    }
    
    /// Hide a channel and remove a channel presenter from items.
    ///
    /// - Parameters:
    ///   - channelPresenter: a channel presenter.
    ///   - clearHistory: checks if needs to remove a message history of the channel.
    ///   - completion: an empty completion block.
    func hide(_ channelPresenter: ChannelPresenter,
              clearHistory: Bool = false,
              _ completion: @escaping Client.Completion<EmptyData> = { _ in }) {
        rx.hide(channelPresenter, clearHistory: clearHistory).asObservable().bindOnce(to: completion)
    }
    
    /// Mutes a channel from a given `ChannelPresenter`.
    /// - Parameter channelPresenter: a channel presenter.
    func mute(_ channelPresenter: ChannelPresenter,
              _ completion: @escaping Client.Completion<MutedChannelResponse> = { _ in }) {
        rx.mute(channelPresenter).bindOnce(to: completion)
    }
    
    /// Unmutes a channel from a given `ChannelPresenter`.
    /// - Parameter channelPresenter: a channel presenter.
    func unmute(_ channelPresenter: ChannelPresenter,
                _ completion: @escaping Client.Completion<EmptyData> = { _ in }) {
        rx.unmute(channelPresenter).bindOnce(to: completion)
    }
    
    /// Delete a channel and remove the channel presenter from items.
    ///
    /// - Parameters:
    ///   - channelPresenter: a channel presenter.
    ///   - completion: an empty completion block.
    func delete(_ channelPresenter: ChannelPresenter,
                _ completion: @escaping Client.Completion<Channel> = { _ in }) {
        rx.delete(channelPresenter).asObservable().bindOnce(to: completion)
    }
}

// MARK: - Response Parsing

extension ChannelsPresenter {
    func parseChannels(_ channels: [ChannelResponse]) -> ViewChanges {
        let isNextPage = next != pageSize
        var items = isNextPage ? self.items : [PresenterItem]()
        
        if let last = items.last, case .loading = last {
            items.removeLast()
        }
        
        let row = items.count
        
        items.append(contentsOf: channels.map {
            let channelPresenter = ChannelPresenter(response: $0, queryOptions: queryOptions)
            channelPresenter.stopWatchingIfNeeded = stopChannelsWatchingIfNeeded
            onChannelPresenterSetup?(channelPresenter)
            return .channelPresenter(channelPresenter)
        })
        
        if channels.count == (next.limit ?? 0) {
            next = [.channelsNextPageSize, .offset((next.offset ?? 0) + (next.limit ?? 0))]
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
    func parse(event: StreamChatClient.Event) -> Observable<ViewChanges> {
        if event.isNotification {
            return parseNotifications(event: event)
        }
        
        guard let cid = event.cid else {
            return Observable.just(.none)
        }
        
        switch event {
        case .channelUpdated(let channelResponse, _, _):
            if let index = items.firstIndex(where: channelResponse.channel.cid),
                let channelPresenter = items[index].channelPresenter {
                channelPresenter.parse(event: event)
                return Observable.just(.itemsUpdated([index], [], items))
            }
            
        case .channelDeleted:
            if let index = items.firstIndex(where: cid) {
                items.remove(at: index)
                return Observable.just(.itemRemoved(index, items))
            }
            
        case .channelHidden:
            if let index = items.firstIndex(where: cid) {
                items.remove(at: index)
                return Observable.just(.itemRemoved(index, items))
            }
            
        case .messageNew, .messageUpdated:
            return parseMessage(event: event)
            
        case .messageDeleted(let message, _, _, _):
            if let index = items.firstIndex(where: cid),
                let channelPresenter = items[index].channelPresenter {
                channelPresenter.parse(event: event)
                return Observable.just(.itemsUpdated([index], [message], items))
            }
            
        case .messageRead:
            if let index = items.firstIndex(where: cid) {
                return Observable.just(.itemsUpdated([index], [], items))
            }
            
        default:
            break
        }
        
        return Observable.just(.none)
    }
    
    private func parseNotifications(event: StreamChatClient.Event) -> Observable<ViewChanges> {
        switch event {
        case .notificationAddedToChannel(let channel, _, _):
            return parseNewChannel(channel: channel)
        case .notificationMarkAllRead:
            return Observable.just(.reloaded(0, items))
        case .notificationMarkRead(_, let channel, _, _):
            if let index = items.firstIndex(where: channel.cid) {
                return Observable.just(.itemsUpdated([index], [], items))
            }
        default:
            break
        }
        
        return Observable.just(.none)
    }
    
    private func parseMessage(event: StreamChatClient.Event) -> Observable<ViewChanges> {
        guard let cid = event.cid,
            let index = items.firstIndex(where: cid),
            let channelPresenter = items.remove(at: index).channelPresenter else {
                return Observable.just(.none)
        }
        
        channelPresenter.parse(event: event)
        items.insert(.channelPresenter(channelPresenter), at: 0)
        
        if index == 0 {
            return Observable.just(.itemsUpdated([0], [], items))
        }
        
        return Observable.just(.itemMoved(fromRow: index, toRow: 0, items))
    }
    
    private func parseNewChannel(channel: Channel) -> Observable<ViewChanges> {
        guard items.firstIndex(where: channel.cid) == nil else {
            return Observable.just(.none)
        }
        
        // Query channels with current filter to see if the new channel is valid
        return Client.shared.rx.queryChannels(filter: filter & .equal("cid", to: channel.cid))
            .map { [weak self] (channelsResponse) -> ViewChanges in
                guard let self = self, let channel = channelsResponse.first?.channel else {
                    return .none
                }
                
                let channelPresenter = ChannelPresenter(channel: channel, queryOptions: self.queryOptions)
                channelPresenter.stopWatchingIfNeeded = self.stopChannelsWatchingIfNeeded
                self.onChannelPresenterSetup?(channelPresenter)
                // We need to load messages for new channel.
                self.loadChannelMessages(channelPresenter)
                self.items.insert(.channelPresenter(channelPresenter), at: 0)
                
                // Update pagination offset.
                if self.next != self.pageSize {
                    self.next = [.channelsNextPageSize, .offset((self.next.offset ?? 0) + 1)]
                }
                
                return .itemsAdded([0], nil, false, self.items)
        }
    }
    
    private func loadChannelMessages(_ channelPresenter: ChannelPresenter) {
        channelPresenter.rx.parsedMessagesRequest.asObservable()
            .take(1)
            .subscribe(onNext: { [weak self, weak channelPresenter] _ in
                guard let self = self,
                    let channelPresenter = channelPresenter,
                    let index = self.items.firstIndex(where: channelPresenter.channel.cid) else {
                        return
                }
                
                self.actions.onNext(.itemsUpdated([index], [], self.items))
            })
            .disposed(by: disposeBagForInternalRequests)
    }
}
