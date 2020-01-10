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

public extension Reactive where Base == Client {
    
    // MARK: Unread Count
    
    /// Observe an unread count of messages in the channel.
    ///
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    var unreadCount: Driver<UnreadCount> {
        return connection.connected()
            // Subscribe for new messages and read events.
            .flatMapLatest({ [unowned base] _ in
                base.webSocket.rx.response
                    .filter { base.updateUnreadCount($0) }
                    .map { _ in base.unreadCountAtomic.get() }
                    .startWith(base.unreadCountAtomic.get())
                    .unwrap()
            })
            .startWith((0, 0))
            .map { "\($0.0), \($0.1)" }
            .distinctUntilChanged()
            .map { [unowned base] _ in base.unreadCountAtomic.get() ?? (0, 0) }
            .asDriver(onErrorJustReturn: (0, 0))
    }
}
