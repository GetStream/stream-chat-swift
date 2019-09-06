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
            .map { [weak self] in self?.id }
            .unwrap()
            // Start watching the channel.
            .flatMapLatest { Channel(id: $0).query(pagination: .limit(1), queryOptions: .watch) }
            .flatMapLatest { _ in Client.shared.webSocket.response }
            .filter { [weak self] in
                if let self = self, let channelId = $0.channelId {
                    return self.id == channelId
                }
                
                return false
            }
            .map { $0.event }
            .filter { eventTypes.isEmpty || eventTypes.contains($0.type) }
            .share()
    }
}

extension Channel {
    
    /// Observe an unread count of messages in the channel.
    ///
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    public var unreadCount: Driver<Int> {
        return Client.shared.connection.connected()
            .map { [weak self] in self?.id }
            .unwrap()
            // Request channel messages and messageRead's.
            .flatMapLatest { Channel(id: $0).query(pagination: .limit(100), queryOptions: [.state, .watch]) }
            // Check if the channel has read events enabled.
            .filter { $0.channel.config.readEventsEnabled }
            // Update the initial number of unread messages.
            .do(onNext: { [weak self] in self?.setupUnreadCount($0) })
            // Subscribe for new messages and read events.
            .flatMapLatest { [weak self] _ in
                Client.shared.webSocket.response
                    .filter { self?.updateUnreadCount($0) ?? false }
                    .map { _ in self?.unreadCountMVar.get() }
                    .startWith(self?.unreadCountMVar.get(defaultValue: 0))
                    .unwrap()
            }
            .do(onDispose: { [weak self] in self?.unreadCountMVar.set(0) })
            .startWith(0)
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: 0)
    }
    
    func setupUnreadCount(_ channelResponse: ChannelResponse) {
        guard let unreadMessageRead = channelResponse.unreadMessageRead else {
            unreadCountMVar.set(0)
            return
        }
        
        var count = 0
        
        for message in channelResponse.messages.reversed() {
            if message.created > unreadMessageRead.lastReadDate {
                count += 1
            } else {
                break
            }
        }
        
        unreadCountMVar.set(count)
    }
    
    func updateUnreadCount(_ response: WebSocket.Response) -> Bool {
        guard response.channelId == id else {
            return false
        }
        
        if case .messageNew = response.event {
            unreadCountMVar += 1
            return true
        }
        
        if case .messageRead(let messageRead, _) = response.event, messageRead.user.isCurrent {
            unreadCountMVar.set(0)
            return true
        }
        
        return false
    }
}
