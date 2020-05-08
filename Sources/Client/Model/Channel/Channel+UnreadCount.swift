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
    func updateUnreadCount(event: Event) {
        switch event {
        case .messageNew(let message, _, _, _), .notificationMessageNew(let message, _, _, _, _):
            updateUnreadCount(newMessage: message)
        case .messageDeleted(let message, _, _, _):
            updateUnreadCount(deletedMessage: message)
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
            resetUnreadCount(messageRead: .init(user: message.user, lastReadDate: message.created, unreadMessagesCount: 0))
            return
        }
        
        var updatedUnreadCount = unreadCount
        updatedUnreadCount.messages += 1
        
        if message.mentionedUsers.contains(User.current) {
            updatedUnreadCount.mentionedMessages += 1
        }
        
        unreadMessageReadAtomic.set(.init(user: User.current,
                                          lastReadDate: message.created,
                                          unreadMessagesCount: updatedUnreadCount.messages))
        unreadCountAtomic.set(updatedUnreadCount)
    }
    
    private func updateUnreadCount(deletedMessage message: Message) {
        guard message.parentId == nil else {
            return
        }
        
        if message.user.isCurrent {
            resetUnreadCount(messageRead: .init(user: message.user, lastReadDate: message.created, unreadMessagesCount: 0))
            return
        }
        
        guard unreadCount.messages > 0 else {
            return
        }
        
        var updatedUnreadCount = unreadCount
        updatedUnreadCount.messages -= 1
        
        if message.mentionedUsers.contains(User.current), updatedUnreadCount.mentionedMessages > 0 {
            updatedUnreadCount.mentionedMessages -= 1
        }
        
        unreadMessageReadAtomic.set(.init(user: User.current,
                                          lastReadDate: message.created,
                                          unreadMessagesCount: updatedUnreadCount.messages))
        unreadCountAtomic.set(updatedUnreadCount)
    }
}
