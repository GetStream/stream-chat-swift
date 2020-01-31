//
//  ChannelPresenter+Request.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 18/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

// MARK: - Parsing Responses

extension ChannelPresenter {
    
    func parsedChannelResponse(_ channelResponse: Observable<ChannelResponse>) -> Driver<ViewChanges> {
        return channelResponse
            .map { [weak self] in self?.parseResponse($0) ?? .none }
            .filter { $0 != .none }
            .map { [weak self] in self?.mapWithEphemeralMessage($0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    }
    
    @discardableResult
    func parseResponse(_ response: ChannelResponse) -> ViewChanges {
        channelAtomic.set(response.channel)
        let isNextPage = next != pageSize
        var items = isNextPage ? self.items : []
        var isLoadingIndex = -1
        
        if let first = items.first, first.isLoading {
            items.removeFirst()
            isLoadingIndex = 0
        }
        
        if InternetConnection.shared.isAvailable && channel.config.readEventsEnabled {
            unreadMessageReadAtomic.set(response.unreadMessageRead)
            
            if !isNextPage {
                messageReadsToMessageId = [:]
            }
        }
        
        let currentCount = items.count
        let messageReads = InternetConnection.shared.isAvailable && channel.config.readEventsEnabled ? response.messageReads : []
        parse(response.messages, messageReads: messageReads, to: &items, isNextPage: isNextPage)
        self.items = items
        response.channel.calculateUnreadCount(response)
        
        if response.messages.isEmpty {
            return isLoadingIndex == -1 ? .none : .itemRemoved(isLoadingIndex, items)
        }
        
        if items.isEmpty {
            return .none
        }
        
        if isNextPage {
            return .reloaded(max(items.count - currentCount - 1, 0), items)
        }
        
        return .reloaded((items.count - 1), items)
    }
    
    func parsedRepliesResponse(_ repliesResponse: Observable<[Message]>) -> Driver<ViewChanges> {
        return repliesResponse
            .map { [weak self] in self?.parseReplies($0) ?? .none }
            .filter { $0 != .none }
            .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    }
    
    func parseReplies(_ messages: [Message]) -> ViewChanges {
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
                       to items: inout [ChatItem],
                       startIndex: Int = 0,
                       isNextPage: Bool) {
        guard let currentUser = User.current else {
            return
        }
        
        var yesterdayStatusAdded = false
        var todayStatusAdded = false
        var index = startIndex
        var ownMessagesIndexes: [Int] = []
        
        // Add chat items for messages.
        messages.enumerated().forEach { _, message in
            if message.isEmpty {
                return
            }
            
            if parentMessage == nil, message.parentId != nil {
                return
            }
            
            if showStatuses, !yesterdayStatusAdded, message.created.isYesterday {
                yesterdayStatusAdded = true
                items.insert(.status(ChatItem.statusYesterdayTitle,
                                     "at \(DateFormatter.time.string(from: message.created))",
                    false), at: index)
                index += 1
            }
            
            if showStatuses, !todayStatusAdded, message.created.isToday {
                todayStatusAdded = true
                items.insert(.status(ChatItem.statusTodayTitle,
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
                        if messageRead.user != currentUser {
                            if messageRead.lastReadDate > ownMessage.created {
                                readUsers.append(messageRead.user)
                                messageReadsToMessageId[messageRead] = ownMessage.id
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
                removeDuplicatedStatus(statusTitle: ChatItem.statusYesterdayTitle, items: &items)
            }
            
            if todayStatusAdded {
                removeDuplicatedStatus(statusTitle: ChatItem.statusTodayTitle, items: &items)
            }
        }
        
        if messages.count == (isNextPage ? Pagination.messagesNextPageSize : pageSize).limit,
            let first = messages.first {
            next = .messagesNextPageSize + .lessThan(first.id)
            items.insert(.loading(false), at: startIndex)
        } else {
            next = pageSize
        }
    }
    
    private func removeDuplicatedStatus(statusTitle: String, items: inout [ChatItem]) {
        if let firstIndex = items.firstIndex(whereStatusTitle: statusTitle),
            let lastIndex = items.lastIndex(whereStatusTitle: statusTitle),
            firstIndex != lastIndex {
            items.remove(at: lastIndex)
        }
    }
}
