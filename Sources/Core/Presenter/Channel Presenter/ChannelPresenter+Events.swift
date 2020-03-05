//
//  ChannelPresenter+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - Events to View Changes

extension ChannelPresenter {
    
    @discardableResult
    func parseEvents(event: Event) -> ViewChanges {
        if let lastWebSocketEvent = lastParsedEvent,
            event == lastWebSocketEvent,
            let lastViewChanges = lastWebSocketEventViewChanges {
            return lastViewChanges
        }
        
        lastParsedEvent = event
        lastWebSocketEventViewChanges = nil
        
        switch event {
        case .typingStart(let user, _):
            guard parentMessage == nil else {
                return .none
            }
            
            let shouldUpdate = filterInvalidatedTypingUsers()
            
            if channel.config.typingEventsEnabled,
                !user.isCurrent,
                (typingUsers.isEmpty || !typingUsers.contains(.init(user: user))) {
                typingUsers.append(.init(user: user))
                return .footerUpdated
            }
            
            if shouldUpdate {
                return .footerUpdated
            }
            
        case .typingStop(let user, _):
            guard parentMessage == nil else {
                return .none
            }
            
            let shouldUpdate = filterInvalidatedTypingUsers()
            
            if channel.config.typingEventsEnabled, !user.isCurrent, let index = typingUsers.firstIndex(of: .init(user: user)) {
                typingUsers.remove(at: index)
                return .footerUpdated
            }
            
            if shouldUpdate {
                return .footerUpdated
            }
            
        case .messageNew(let message, let unreadCount, _, let messageNewChannel, let type):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
            // A new message event.
            if case .messageNew = type {
                if channel.config.readEventsEnabled, !message.user.isCurrent {
                    channel.unreadCountAtomic += 1
                    
                    if let lastMessage = lastMessageAtomic.get() {
                        unreadMessageReadAtomic.set(MessageRead(user: lastMessage.user, lastReadDate: lastMessage.updated))
                    } else {
                        unreadMessageReadAtomic.set(MessageRead(user: message.user, lastReadDate: message.updated))
                    }
                } else {
                    unreadMessageReadAtomic.set(nil)
                }
            } else {
                // A notification new message event.
                if let messageNewChannel = messageNewChannel {
                    channelAtomic.set(messageNewChannel)
                }
                
                channel.unreadCountAtomic.set(unreadCount)
                
                if unreadCount > 0, unreadMessageReadAtomic.get() == nil {
                    unreadMessageReadAtomic.set(MessageRead(user: message.user, lastReadDate: message.updated))
                }
            }
            
            let newStatusAdded = addStatusIfNeeded(for: message)
            let nextRow = items.count
            let reloadRow: Int? = items.last?.message?.user == message.user ? nextRow - 1 : nil
            appendOrUpdateMessageItem(message)
            let viewChanges = ViewChanges.itemsAdded(newStatusAdded ? [nextRow - 1, nextRow] : [nextRow],
                                                     reloadRow,
                                                     message.user.isCurrent,
                                                     items)
            lastWebSocketEventViewChanges = viewChanges
            channel.add(messagesToDatabase: [message])
            Notifications.shared.showIfNeeded(newMessage: message, in: channel)
            
            return viewChanges
            
        case .messageUpdated(let message, _),
             .messageDeleted(let message, _):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
            if let index = items.lastIndex(whereMessageId: message.id) {
                appendOrUpdateMessageItem(message, at: index)
                let viewChanges = ViewChanges.itemsUpdated([index], [message], items)
                lastWebSocketEventViewChanges = viewChanges
                return viewChanges
            }
            
        case .reactionNew(let reaction, let message, _, _),
             .reactionUpdated(let reaction, let message, _, _),
             .reactionDeleted(let reaction, let message, _, _):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
            if let index = items.lastIndex(whereMessageId: message.id) {
                var message = message
                
                if reaction.isOwn, let currentMessage = items[index].message {
                    if case .reactionDeleted = event {
                        message.delete(reaction: reaction, fromOwnReactions: currentMessage.ownReactions)
                    } else {
                        message.addOrUpdate(reaction: reaction, toOwnReactions: currentMessage.ownReactions)
                    }
                }
                
                appendOrUpdateMessageItem(message, at: index)
                let viewChanges = ViewChanges.itemsUpdated([index], [message], items)
                lastWebSocketEventViewChanges = viewChanges
                return viewChanges
            }
            
        case .messageRead(let messageRead, _):
            guard channel.config.readEventsEnabled, let currentUser = User.current, messageRead.user != currentUser else {
                return .none
            }
            
            channel.unreadCountAtomic.set(0)
            
            guard  let lastAddedOwnMessage = lastAddedOwnMessage,
                lastAddedOwnMessage.created <= messageRead.lastReadDate,
                let lastOwnMessageIndex = items.lastIndex(whereMessageId: lastAddedOwnMessage.id) else {
                    return .none
            }
            
            var rows: [Int] = []
            var messages: [Message] = []
            
            // Reload old position.
            if let messageId = messageReadsToMessageId[messageRead], let index = items.lastIndex(whereMessageId: messageId) {
                if index == lastOwnMessageIndex {
                    return .none
                }
                
                if case let .message(message, readUsers) = items[index] {
                    var readUsers = readUsers
                    readUsers.removeAll { $0.id == messageRead.user.id }
                    items[index] = .message(message, readUsers)
                    rows.append(index)
                    messages.append(message)
                }
            }
            
            // Reload new position.
            if case let .message(_, readUsers) = items[lastOwnMessageIndex] {
                var readUsers = readUsers
                readUsers.append(messageRead.user)
                items[lastOwnMessageIndex] = .message(lastAddedOwnMessage, readUsers)
                rows.append(lastOwnMessageIndex)
                messages.append(lastAddedOwnMessage)
                messageReadsToMessageId[messageRead] = lastAddedOwnMessage.id
            }
            
            return .itemsUpdated(rows, messages, items)
            
        case .channelUpdated(let response, _):
            channelAtomic.set(response.channel)
            
        default:
            break
        }
        
        return .none
    }
    
    private func addStatusIfNeeded(for newMessage: Message) -> Bool {
        guard let lastMessage = items.last?.message else { return false }
        guard newMessage.created.isToday, !lastMessage.created.isToday else { return false }
        
        items.append(.status(ChatItem.statusTodayTitle,
                             "at \(DateFormatter.time.string(from: newMessage.created))",
                             false))
        return true
    }
    
    private func appendOrUpdateMessageItem(_ message: Message, at index: Int = -1) {
        lastMessageAtomic.set(message)
        
        if index == -1 {
            if message.isOwn {
                lastAddedOwnMessage = message
            }
            
            items.append(.message(message, []))
        } else if index < items.count {
            items[index] = .message(message, items[index].messageReadUsers)
        }
    }
    
    private func shouldMessageEventBeHandled(_ message: Message) -> Bool {
        guard let parentMessage = parentMessage else {
            return message.parentId == nil
        }
        
        return message.parentId == parentMessage.id || message.id == parentMessage.id
    }
    
    private func filterInvalidatedTypingUsers() -> Bool {
        let count = typingUsers.count
        typingUsers = typingUsers.filter { $0.started.timeIntervalSinceNow > -TypingUser.timeout }
        return typingUsers.count != count
    }
}
