//
//  Channel+RxEvents.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 08/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift
import RxCocoa

// MARK: Events

public extension Reactive where Base == Channel {
    
    /// Observe channel events.
    /// - Parameter eventType: an event type.
    /// - Returns: observable events.
    func onEvent(eventType: EventType) -> Observable<StreamChatClient.Event> {
        onEvent([eventType])
    }
    
    /// Observe a list of events with a given channel id (optional).
    ///
    /// - Parameter eventType: an event type.
    /// - Returns: observable events.
    func onEvent(eventTypes: [EventType] = []) -> Observable<StreamChatClient.Event> {
        Client.shared.rx.connected
            .flatMapLatest { self.watch() }
            .flatMapLatest { _ in Client.shared.rx.onEvent }
            .filter({ [weak base] in
                if let base = base {
                    if let cid = $0.cid {
                        return base.cid == cid
                    }
                    
                    if case .userBanned(_, _, _, let cid, _) = $0 {
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
        unreadCount.asObservable().map({ $0.messages > 0 }).asDriver(onErrorJustReturn: false)
    }
    
    var unreadCount: Driver<ChannelUnreadCount> {
        Client.shared.rx.connected
            // Request channel messages and messageRead's.
            .flatMapLatest({ [weak base] _ -> Observable<ChannelResponse> in
                if let base = base {
                    return Channel(type: base.type, id: base.id).rx.query(pagination: .limit(100), options: [.state, .watch])
                }
                
                return .empty()
            })
            // Check if the channel has read events enabled.
            .takeUntil(.exclusive, predicate: { !$0.channel.config.readEventsEnabled })
            // Subscribe for new messages and read events.
            .flatMapLatest({ [weak base] _ -> Observable<ChannelUnreadCount> in
                self.onEvent(eventTypes: [.messageNew, .notificationMessageNew, .notificationMarkRead])
                    .map { _ in base?.unreadCount }
                    .unwrap()
                    .dis
                    .startWith(base?.unreadCount ?? .empty )
            })
            .asDriver(onErrorJustReturn: .empty)
    }
    
    // MARK: - Users Presence
    
    /// Online users in the channel.
    /// - Note: Be sure users are members of the channel.
    var onlineUsers: Driver<Set<User>> {
        return Client.shared.rx.connected
            // Request channel for members.
            .flatMapLatest { [unowned base] in Channel(type: base.type, id: base.id).rx.query(options: .presence) }
            // Map members to online users.
            .flatMapLatest { response -> Observable<Set<User>> in
                // Subscribe for user presence changes.
                Client.shared.rx.onEvent(.userPresenceChanged)
                    .map { response.channel.onlineUsers }
                    .startWith(response.channel.onlineUsers)
            }
            .asDriver(onErrorJustReturn: [])
    }
}
