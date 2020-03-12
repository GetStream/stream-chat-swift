//
//  Client+RxWatcherCount.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

public extension Reactive where Base == Client {
    /// Observe a watcher count of users for a given channel.
    func watcherCount(channel: Channel) -> Observable<Int> {
        queryChannel(channel, messagesPagination: .limit(1), options: [.watch, .state])
            .map { $0.channel }
            .flatMapLatest({ [unowned base] channel -> Observable<Int> in
                base.rx.onEvent(eventTypes: [.userStartWatching,
                                             .userStopWatching,
                                             .messageNew,
                                             .notificationMessageNew], channel: channel)
                    .map { _ in channel.watcherCount }
                    .startWith(channel.watcherCount)
            })
    }
}
