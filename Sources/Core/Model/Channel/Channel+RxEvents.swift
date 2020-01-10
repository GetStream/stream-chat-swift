//
//  Channel+RxEvents.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 08/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: Events

public extension Reactive where Base == Channel {
    
    /// Observe channel events.
    ///
    /// - Parameter eventType: an event type.
    /// - Returns: observable events.
    func onEvent(_ eventType: EventType) -> Observable<Event> {
        return onEvent([eventType])
    }
    
    /// Observe a list of events with a given channel id (optional).
    ///
    /// - Parameter eventType: an event type.
    /// - Returns: observable events.
    func onEvent(_ eventTypes: [EventType] = []) -> Observable<Event> {
        return Client.shared.rx.connection.connected()
            .flatMapLatest { self.query(options: .watch) }
            .flatMapLatest { _ in Client.shared.webSocket.rx.response }
            .filter({ [weak base] in
                if let base = base {
                    if let cid = $0.cid {
                        return base.id == cid.id && base.type == cid.type
                    }
                    
                    if case .userBanned(let cid, _, _, _, _) = $0.event {
                        return cid == base.cid
                    }
                }
                
                return false
            })
            .map { $0.event }
            .filter { eventTypes.isEmpty || eventTypes.contains($0.type) }
            .share()
    }
    
    // MARK: - Unread Count
    
    /// An observable isUnread state of the channel.
    var isUnread: Driver<Bool> {
        return unreadCount.map { $0 > 0 }
    }
    
    /// Observe an unread count of messages in the channel.
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    var unreadCount: Driver<Int> {
        return createUnreadCount().compactMap({ $0.0 }).startWith(0).distinctUntilChanged().asDriver(onErrorJustReturn: 0)
    }
    
    /// Observe a user mentioned unread count of messages in the channel.
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    var mentionedUnreadCount: Driver<Int> {
        return createUnreadCount().compactMap({ $0.1 }).startWith(0).distinctUntilChanged().asDriver(onErrorJustReturn: 0)
    }
    
    private func createUnreadCount() -> Observable<(Int?, Int?)> {
        return Client.shared.rx.connection.connected()
            // Request channel messages and messageRead's.
            .flatMapLatest({ [weak base] _ -> Observable<ChannelResponse> in
                if let base = base {
                    return Channel(type: base.type, id: base.id).rx.query(pagination: .limit(100), options: [.state, .watch])
                }
                
                return .empty()
            })
            // Check if the channel has read events enabled.
            .takeUntil(.exclusive, predicate: { !$0.channel.config.readEventsEnabled })
            // Update the initial number of unread messages.
            .do(onNext: { [weak base] in base?.calculateUnreadCount($0) })
            // Subscribe for new messages and read events.
            .flatMapLatest({ [weak base] _ in
                Client.shared.webSocket.rx.response
                    .filter { base?.updateUnreadCount($0) ?? false }
                    .map { _ in (base?.unreadCountAtomic.get(), base?.mentionedUnreadCountAtomic.get()) }
                    .startWith((base?.unreadCountAtomic.get(), base?.mentionedUnreadCountAtomic.get()))
            })
    }
    
    // MARK: - Users Presence
    
    /// Online users in the channel.
    /// - Note: Be sure users are members of the channel.
    var onlineUsers: Driver<[User]> {
        return Client.shared.rx.connection.connected()
            // Request channel for members.
            .flatMapLatest { [weak base] _ -> Observable<ChannelResponse> in
                if let base = base {
                    return Channel(type: base.type, id: base.id).rx.query(options: .presence)
                }
                
                return .empty()
            }
            // Map members to online users.
            .map { $0.channel.members.filter({ $0.user.isOnline }).map({ $0.user }) }
            .flatMapLatest{ [weak base] onlineUsers -> Observable<[User]> in
                guard let base = base else {
                    return .empty()
                }
                
                base.onlineUsersAtomic.set(onlineUsers)
                
                // Subscribe for user presence changes.
                return Client.shared.rx.onEvent(.userPresenceChanged)
                    .map { [weak base] event -> [User] in
                        guard let base = base, case .userPresenceChanged(let user, _) = event else {
                            return []
                        }
                        
                        var onlineUsers = base.onlineUsersAtomic.get(defaultValue: [])
                        
                        if user.isOnline {
                            if !onlineUsers.contains(user) {
                                onlineUsers.insert(user, at: 0)
                            }
                        } else {
                            if let index = onlineUsers.firstIndex(of: user) {
                                onlineUsers.remove(at: index)
                            }
                        }
                        
                        base.onlineUsersAtomic.set(onlineUsers)
                        
                        return onlineUsers
                    }
                    .startWith(onlineUsers)
            }
            .map { onlineUsers in
                if let currentUser = User.current {
                    return onlineUsers.filter({ $0 != currentUser })
                }
                
                return []
            }
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: [])
    }
}
