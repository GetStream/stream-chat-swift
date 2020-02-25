//
//  Client+OnlineUsers.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 07/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Online Users

extension Channel {
    
    /// Update the unread count if needed.
    /// - Parameter response: a web socket event.
    func updateChannelOnlineUsers(event: Event) {
        guard case .userPresenceChanged(let user, _, _) = event, !user.isCurrent else {
            return
        }
        
        var onlineUsers = onlineUsersAtomic.get(default: [])
        
        if user.isOnline {
            if !onlineUsers.contains(user) {
                onlineUsers.insert(user)
            }
        } else {
            onlineUsers.remove(user)
        }
        
        onlineUsersAtomic.set(onlineUsers)
    }
}
