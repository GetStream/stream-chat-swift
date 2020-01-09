//
//  Client+RxUnreadCount.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: Unread Count

public typealias UnreadCount = (channels: Int, messages: Int)

public extension Reactive where Base == Client {
    
    /// Observe an unread count of messages in the channel.
    ///
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    var unreadCount: Driver<UnreadCount> {
        return connection.connected()
            // Subscribe for new messages and read events.
            .flatMapLatest({ [unowned base] _ in
                base.webSocket.response
                    .filter { self.updateUnreadCount($0) }
                    .map { [unowned base] _ in base.unreadCountAtomic.get() }
                    .startWith(base.unreadCountAtomic.get())
                    .unwrap()
            })
            .startWith((0, 0))
            .map { "\($0.0), \($0.1)" }
            .distinctUntilChanged()
            .map { [unowned base] _ in base.unreadCountAtomic.get() ?? (0, 0) }
            .asDriver(onErrorJustReturn: (0, 0))
    }
    
    func updateUnreadCount(_ response: WebSocket.Response) -> Bool {
        switch response.event {
        case .notificationMarkRead(_, let messagesUnreadCount, let channelsUnreadCount, _),
             .messageNew(_, let messagesUnreadCount, let channelsUnreadCount, _, _):
            base.unreadCountAtomic.set((channelsUnreadCount, messagesUnreadCount))
            return true
        default:
            return false
        }
    }
}
