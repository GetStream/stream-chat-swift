//
//  Channel+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 08/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - Events

public extension Channel {
    
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
        return Client.shared.connection.connected()
            .flatMapLatest { [weak self] _ -> Observable<ChannelResponse> in
                if let self = self {
                    return self.query(options: .watch)
                }
                
                return .empty()
            }
            .flatMapLatest { _ in Client.shared.webSocket.response }
            .filter { [weak self] in
                if let self = self {
                    if let cid = $0.cid {
                        return self.id == cid.id && self.type == cid.type
                    }
                    
                    if case .userBanned(let cid, _, _, _, _) = $0.event {
                        return cid == self.cid
                    }
                }
                
                return false
            }
            .map { $0.event }
            .filter { eventTypes.isEmpty || eventTypes.contains($0.type) }
            .share()
    }
}

// MARK: - Unread Count

extension Channel {
    
    /// An observable isUnread state of the channel.
    public var isUnread: Driver<Bool> {
        return unreadCount.map { $0 > 0 }
    }
    
    /// Observe an unread count of messages in the channel.
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    public var unreadCount: Driver<Int> {
        return createUnreadCount().compactMap({ $0.0 }).startWith(0).distinctUntilChanged().asDriver(onErrorJustReturn: 0)
    }
    
    /// Observe a user mentioned unread count of messages in the channel.
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    public var mentionedUnreadCount: Driver<Int> {
        return createUnreadCount().compactMap({ $0.1 }).startWith(0).distinctUntilChanged().asDriver(onErrorJustReturn: 0)
    }
    
    private func createUnreadCount() -> Observable<(Int?, Int?)> {
        return Client.shared.connection.connected()
            // Request channel messages and messageRead's.
            .flatMapLatest({ [weak self] _ -> Observable<ChannelResponse> in
                if let self = self {
                    return Channel(type: self.type, id: self.id)
                        .query(pagination: .limit(100), options: [.state, .watch])
                }
                
                return .empty()
            })
            // Check if the channel has read events enabled.
            .takeUntil(.exclusive, predicate: { !$0.channel.config.readEventsEnabled })
            // Update the initial number of unread messages.
            .do(onNext: { [weak self] in self?.calculateUnreadCount($0) })
            // Subscribe for new messages and read events.
            .flatMapLatest({ [weak self] _ in
                Client.shared.webSocket.response
                    .filter { self?.updateUnreadCount($0) ?? false }
                    .map { _ in (self?.unreadCountAtomic.get(), self?.mentionedUnreadCountAtomic.get()) }
                    .startWith((self?.unreadCountAtomic.get(), self?.mentionedUnreadCountAtomic.get()))
            })
    }
    
    func calculateUnreadCount(_ channelResponse: ChannelResponse) {
        unreadCountAtomic.set(0)
        mentionedUnreadCountAtomic.set(0)
        
        guard let currentUser = User.current, let unreadMessageRead = channelResponse.unreadMessageRead else {
            return
        }
        
        var count = 0
        var mentionedCount = 0
        
        for message in channelResponse.messages.reversed() {
            if message.created > unreadMessageRead.lastReadDate {
                count += 1
                
                if message.user != currentUser, message.mentionedUsers.contains(currentUser) {
                    mentionedCount += 1
                }
            } else {
                break
            }
        }
        
        unreadCountAtomic.set(count)
        mentionedUnreadCountAtomic.set(mentionedCount)
    }
    
    /// Update the unread count if needed.
    ///
    /// - Parameter response: a web socket event.
    /// - Returns: true, if unread count was updated.
    @discardableResult
    func updateUnreadCount(_ response: WebSocket.Response) -> Bool {
        guard let currentUser = User.current else {
            return false
        }
        
        guard let cid = response.cid, cid.id == id, cid.type == type else {
            if case .notificationMarkRead(let notificationChannel, let unreadCount, _, _) = response.event,
                let channel = notificationChannel,
                channel.id == id {
                unreadCountAtomic.set(unreadCount)
                return true
            }
            
            return false
        }
        
        if case .messageNew(let message, let unreadCount, _, _, _) = response.event {
            unreadCountAtomic.set(unreadCount)
            
            if message.user != currentUser, message.mentionedUsers.contains(currentUser) {
                mentionedUnreadCountAtomic += 1
            }
            
            return true
        }
        
        if case .messageRead(let messageRead, _) = response.event, messageRead.user.isCurrent {
            unreadCountAtomic.set(0)
            mentionedUnreadCountAtomic.set(0)
            return true
        }
        
        return false
    }
}

// MARK: - Users Presence

extension Channel {
    
    /// Online users in the channel.
    /// - Note: Be sure users are members of the channel.
    public var onlineUsers: Driver<[User]> {
        return Client.shared.connection.connected()
            // Request channel for members.
            .flatMapLatest { [weak self] _ -> Observable<ChannelResponse> in
                if let self = self {
                    return Channel(type: self.type, id: self.id).query(options: .presence)
                }
                
                return .empty()
            }
            // Map members to online users.
            .map { $0.channel.members.filter({ $0.user.isOnline }).map({ $0.user }) }
            .flatMapLatest { [weak self] onlineUsers -> Observable<[User]> in
                guard let self = self else {
                    return .empty()
                }
                
                self.onlineUsersAtomic.set(onlineUsers)
                
                // Subscribe for user presence changes.
                return Client.shared.onEvent(.userPresenceChanged)
                    .map { [weak self] event -> [User] in
                        guard let self = self, case .userPresenceChanged(let user, _) = event else {
                            return []
                        }
                        
                        var onlineUsers = self.onlineUsersAtomic.get(defaultValue: [])
                        
                        if user.isOnline {
                            if !onlineUsers.contains(user) {
                                onlineUsers.insert(user, at: 0)
                            }
                        } else {
                            if let index = onlineUsers.firstIndex(of: user) {
                                onlineUsers.remove(at: index)
                            }
                        }
                        
                        self.onlineUsersAtomic.set(onlineUsers)
                        
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
