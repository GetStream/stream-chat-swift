//
//  ChannelPresenter+Request.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient
import RxSwift
import RxCocoa

// MARK: - Parsing Responses

extension ChannelPresenter {
    
    @discardableResult
    func parse(response: ChannelResponse) -> ViewChanges {
        channelAtomic.set(response.channel)
        let isNextPage = next != pageSize
        var items = isNextPage ? self.items : []
        var isLoadingIndex = -1
        
        if let first = items.first, first.isLoading {
            items.removeFirst()
            isLoadingIndex = 0
        }
        
        if InternetConnection.shared.isAvailable, channel.readEventsEnabled, !isNextPage {
            messageIdByMessageReadUser = [:]
        }
        
        let currentCount = items.count
        let messageReads = InternetConnection.shared.isAvailable && channel.readEventsEnabled ? response.messageReads : []
        parse(response.messages, messageReads: messageReads, to: &items, isNextPage: isNextPage)
        self.items = items
        
        if response.messages.isEmpty {
            return isLoadingIndex == -1 ? .none : .itemRemoved(isLoadingIndex, items)
        }
        
        if items.isEmpty {
            return .none
        }
        
        let scrollToRow = max(items.count - currentCount - 1, 0)
        return .reloaded(scrollToRow, items)
    }
    
    func parse(replies messages: [Message]) -> ViewChanges {
        guard let parentMessage = parentMessage else {
            return .none
        }
        
        let isNextPage = next != pageSize
        var items = isNextPage ? self.items : []
        
        if items.isEmpty {
            items.append(.message(parentMessage, []))
            items.append(.status("Start of thread", nil, false))
        }
        
        if let loadingIndex = items.firstIndexWhereStatusLoading() {
            items.remove(at: loadingIndex)
        }
        
        let currentCount = items.count
        parse(messages, to: &items, startIndex: 2, isNextPage: isNextPage)
        self.items = items
        
        return isNextPage ? .reloaded(max(items.count - currentCount - 1, 0), items) : .reloaded((items.count - 1), items)
    }
    
    private func parse(_ messages: [Message],
                       messageReads: [MessageRead] = [],
                       to items: inout [PresenterItem],
                       startIndex: Int = 0,
                       isNextPage: Bool) {
        var yesterdayStatusAdded = false
        var todayStatusAdded = false
        var index = startIndex
        var ownMessagesIndexes: [Int] = []
        
        // Add chat items for messages.
        messages.forEach { message in
            if message.isEmpty {
                return
            }
            
            if !isThread, message.isReply, !message.showReplyInChannel {
                return
            }
            
            if showStatuses, !yesterdayStatusAdded, message.created.isYesterday {
                yesterdayStatusAdded = true
                items.insert(.status(PresenterItem.statusYesterdayTitle,
                                     "at \(DateFormatter.time.string(from: message.created))",
                    false), at: index)
                index += 1
            }
            
            if showStatuses, !todayStatusAdded, message.created.isToday {
                todayStatusAdded = true
                items.insert(.status(PresenterItem.statusTodayTitle,
                                     "at \(DateFormatter.time.string(from: message.created))",
                    false), at: index)
                index += 1
            }
            
            if message.isOwn {
                lastAddedOwnMessage = message
                ownMessagesIndexes.append(index)
            }
            
            lastMessageAtomic.set(message)
            items.insert(.message(message, []), at: index)
            index += 1
        }
        
        // Add read users.
        if !messageReads.isEmpty, !ownMessagesIndexes.isEmpty {
            var messageReads = messageReads
            
            for ownMessagesIndex in ownMessagesIndexes.reversed() {
                if let ownMessage = items[ownMessagesIndex].message {
                    var leftMessageReads: [MessageRead] = []
                    var readUsers: [User] = []
                    
                    messageReads.forEach { messageRead in
                        if messageRead.user != User.current {
                            if messageRead.lastReadDate > ownMessage.created {
                                readUsers.append(messageRead.user)
                                messageIdByMessageReadUser[messageRead.user] = ownMessage.id
                            } else {
                                leftMessageReads.append(messageRead)
                            }
                        }
                    }
                    
                    if !readUsers.isEmpty {
                        items[ownMessagesIndex] = .message(ownMessage, readUsers)
                    }
                    
                    messageReads = leftMessageReads
                    
                    if messageReads.isEmpty {
                        break
                    }
                }
            }
        }
        
        if isNextPage {
            if yesterdayStatusAdded {
                removeDuplicatedStatus(statusTitle: PresenterItem.statusYesterdayTitle, items: &items)
            }
            
            if todayStatusAdded {
                removeDuplicatedStatus(statusTitle: PresenterItem.statusTodayTitle, items: &items)
            }
        }
        
        if messages.count == (isNextPage ? [.messagesNextPageSize] : pageSize).limit ?? 0,
            let first = messages.first {
            next = [.messagesNextPageSize, .lessThan(first.id)]
            items.insert(.loading(false), at: startIndex)
        } else {
            next = pageSize
        }
    }
    
    private func removeDuplicatedStatus(statusTitle: String, items: inout [PresenterItem]) {
        if let firstIndex = items.firstIndex(whereStatusTitle: statusTitle),
            let lastIndex = items.lastIndex(whereStatusTitle: statusTitle),
            firstIndex != lastIndex {
            items.remove(at: lastIndex)
        }
    }
}
