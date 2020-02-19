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
        onUserUpdate.map({ $0.unreadCount }).startWith(base.user.unreadCount)
    }
    
    /// Observe an unread count of messages and mentioned messages for a given channel.
    /// - Note: Be sure the current user is a member of the channel.
    /// - Note: 100 is the maximum unread count of messages.
    /// - Parameter channel: a channel.
    func channelUnreadCount(_ channel: Channel) -> Observable<ChannelUnreadCount> {
        queryChannel(channel, pagination: .limit(100), options: [.state, .watch])
            .map { $0.channel }
            .flatMapLatest({ [unowned base] channel -> Observable<ChannelUnreadCount> in
                base.rx.onEvent(channel: channel)
                    .map({ _ in channel.unreadCount })
                    .startWith(channel.unreadCount)
            })
    }
}
