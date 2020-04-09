//
//  Client+RxUnreadCount.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

// MARK: Unread Count

public extension Reactive where Base == Client {
    
    /// Observe an unread count of messages and channels.
    var unreadCount: Observable<UnreadCount> {
        connectionState
            .filter({ $0.isConnected })
            .flatMapLatest({ [unowned base] _ -> Observable<UnreadCount> in
                Observable<UnreadCount>.create({ observer in
                    let subscription = base.subscribeToUnreadCount { observer.onNext($0) }
                    return Disposables.create { subscription.cancel() }
                })
                    .distinctUntilChanged()
            })
    }
}
