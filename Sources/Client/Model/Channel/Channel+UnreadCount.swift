//
//  Channel+UnreadCount.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 25/02/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

extension Channel {
    
    /// Update the unread count if needed.
    /// - Parameters:
    ///   - channel: a channel.
    ///   - event: an event.
    func updateChannelUnreadCount(event: Event) {
        switch event {
        case let .messageNew(message, _, _, _):
            if message.user.isCurrent {
                resetUnreadCount(messageRead: .init(user: message.user, lastReadDate: message.created))
                return
            }
            
            var unreadCount = self.unreadCount
            unreadCount.messages += 1
            
            if !message.user.isCurrent, message.mentionedUsers.contains(User.current) {
                unreadCount.mentionedMessages += 1
            }
            
            unreadMessageReadAtomic.set(.init(user: User.current, lastReadDate: message.created))
            unreadCountAtomic.set(unreadCount)
            
        case .messageRead(let messageRead, _, _):
            if messageRead.user.isCurrent {
                resetUnreadCount(messageRead: messageRead)
            }
            
        default:
            break
        }
    }
}
