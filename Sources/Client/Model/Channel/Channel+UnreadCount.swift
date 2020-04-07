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
    ///   - channelEvent: an event.
    func updateUnreadCount(channelEvent: ChannelEvent) {
        switch channelEvent {
        case .messageNew(let message, _, _, _):
            updateUnreadCount(newMessage: message)
        case .messageRead(let messageRead, _, _):
            if messageRead.user.isCurrent {
                resetUnreadCount(messageRead: messageRead)
            }
        default:
            break
        }
    }
    
    func updateUnreadCount(newMessage message: Message) {
        guard message.parentId == nil else {
            return
        }
        
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
    }
}
