//
//  Channel+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 10/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift

public extension Channel {
    // MARK: - Unread Count
    
    /// An observable channel unread count.
    func unreadCount(_ onNext: @escaping Client.Completion<ChannelUnreadCount>) -> AutoCancellingSubscription {
        rx.unreadCount.bind(to: onNext)
    }
    
    /// An observable channel isUnread state.
    func isUnread(_ onNext: @escaping Client.Completion<Bool>) -> AutoCancellingSubscription {
        rx.isUnread.bind(to: onNext)
    }
    
    // MARK: - Users Presence
    
    /// Observe a watcher count of users for the channel.
    func watcherCount(_ onNext: @escaping Client.Completion<Int>) -> AutoCancellingSubscription {
        rx.watcherCount.bind(to: onNext)
    }
}
