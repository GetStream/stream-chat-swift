//
//  ChannelPresenter+Events.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift
import RxCocoa

// MARK: - Events to View Changes

extension ChannelPresenter {
    
    @discardableResult
    func parse(event: StreamChatClient.Event) -> ViewChanges {
        if let lastWebSocketEvent = lastParsedEvent,
            event == lastWebSocketEvent,
            let lastViewChanges = lastWebSocketEventViewChanges {
            return lastViewChanges
        }
        
        lastParsedEvent = event
        lastWebSocketEventViewChanges = nil
        
        switch event {
        case .typingStart(let user, _, _):
            guard isTypingEventsEnabled else {
                return .none
            }
            
            let shouldUpdate = filterInvalidatedTypingUsers()
            
            if !user.isCurrent, (typingUsers.isEmpty || !typingUsers.contains(.init(user: user))) {
                typingUsers.append(.init(user: user))
                return .footerUpdated
            }
            
            if shouldUpdate {
                return .footerUpdated
            }
            
        case .typingStop(let user, _, _):
            guard isTypingEventsEnabled else {
                return .none
            }
            
            let shouldUpdate = filterInvalidatedTypingUsers()
            
            if !user.isCurrent, let index = typingUsers.firstIndex(of: .init(user: user)) {
                typingUsers.remove(at: index)
                return .footerUpdated
            }
            
            if shouldUpdate {
                return .footerUpdated
            }
            
        case .messageNew(let message, _, _, _):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
            let nextRow = items.count
            let reloadRow: Int? = items.last?.message?.user == message.user ? nextRow - 1 : nil
            appendOrUpdateMessageItem(message)
            let viewChanges = ViewChanges.itemsAdded([nextRow], reloadRow, message.user.isCurrent, items)
            lastWebSocketEventViewChanges = viewChanges
            Notifications.shared.showIfNeeded(newMessage: message, in: channel)
            
            return viewChanges
            
        case .messageUpdated(let message, _, _),
             .messageDeleted(let message, _, _, _):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
            if let index = items.lastIndex(whereMessageId: message.id) {
                appendOrUpdateMessageItem(message, at: index)
                let viewChanges = ViewChanges.itemsUpdated([index], [message], items)
                lastWebSocketEventViewChanges = viewChanges
                return viewChanges
            }
            
        case .reactionNew(let reaction, let message, _, _, _),
             .reactionDeleted(let reaction, let message, _, _, _):
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
            
        case .messageRead(let messageRead, _, _):
            guard channel.config.readEventsEnabled,
                messageRead.user != User.current,
                let lastAddedOwnMessage = lastAddedOwnMessage,
                lastAddedOwnMessage.created <= messageRead.lastReadDate,
                let lastOwnMessageIndex = items.lastIndex(whereMessageId: lastAddedOwnMessage.id) else {
                    return .none
            }
            
            var rows: [Int] = []
            var messages: [Message] = []
            
            // Reload old position.
            if let messageId = messageIdByMessageReadUser[messageRead.user],
                let index = items.lastIndex(whereMessageId: messageId) {
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
                messageIdByMessageReadUser[messageRead.user] = lastAddedOwnMessage.id
            }
            
            return .itemsUpdated(rows, messages, items)
            
        case .channelUpdated(let response, _, _):
            channelAtomic.set(response.channel)
            
        default:
            break
        }
        
        return .none
    }
    
    private func appendOrUpdateMessageItem(_ message: Message, at index: Int = -1) {
        switch lastMessage {
        case .none:
            lastMessageAtomic.set(message)
        case .some(let lastMessage):
            if message.created > lastMessage.created || message.id == lastMessage.id {
                lastMessageAtomic.set(message)
            }
        }
        
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
            return !message.isReply || message.showReplyInChannel
        }
        
        return message.parentId == parentMessage.id || message.id == parentMessage.id
    }
    
    private func filterInvalidatedTypingUsers() -> Bool {
        let count = typingUsers.count
        typingUsers = typingUsers.filter { $0.started.timeIntervalSinceNow > -TypingUser.timeout }
        return typingUsers.count != count
    }
}
