//
//  Client+RxOnlineUsers.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

public extension Reactive where Base == Client {
    
    /// Observe an online users from a given channel.
    func onlineUsers(channel: Channel) -> Observable<Set<User>> {
        connectedRequest(queryChannel(channel, options: [.presence])
            .map { $0.channel }
            .flatMapLatest({ channel -> Observable<Set<User>> in
                self.onEvent(eventType: .userPresenceChanged, channel: channel)
                    .map { _ in channel.onlineUsers }
                    .startWith(channel.onlineUsers)
            }))
    }
}
