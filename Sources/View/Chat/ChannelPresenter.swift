//
//  ChannelPresenter.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public final class ChannelPresenter {
    public typealias Completion = (_ error: Error?) -> Void
    private typealias EphemeralType = (message: Message?, updated: Bool)
    
    public private(set) var channel: Channel
    var members: [Member] = []
    private var next: Pagination = .none
    private var startedTyping = false
    
    private var items: [ChatItem] = []
    private(set) var lastMessage: Message?
    private(set) var isUnread = false
    private(set) var lastMessageRead: MessageRead?
    private(set) var typingUsers: [User] = []
    private let loadPagination = PublishSubject<Pagination>()
    private let ephemeralSubject = BehaviorSubject<EphemeralType>(value: (nil, false))
    private let showStatuses = true
    
    public var itemsCount: Int {
        return items.count + (hasEphemeralMessage ? 1 : 0)
    }
    
    private let emptyMessageCompletion: Client.Completion<MessageResponse> = { _ in }
    
    private lazy var ephemeralMessageCompletion: Client.Completion<MessageResponse> = { [weak self] result in
        if let self = self, let response = try? result.get(), response.message.type == .ephemeral {
            self.ephemeralSubject.onNext((response.message, self.hasEphemeralMessage))
        }
    }
    
    public var hasEphemeralMessage: Bool {
        return ephemeralMessage != nil
    }
    
    public var ephemeralMessage: Message? {
        return (try? ephemeralSubject.value())?.message
    }
    
    private(set) lazy var request: Driver<ViewChanges> =
        Observable.combineLatest(Client.shared.webSocket.connection, loadPagination.asObserver())
            .map { [weak self] in self?.parseConnection($0, pagination: $1) }
            .unwrap()
            .skip(items.isEmpty ? 0 : 1)
            .flatMapLatest { Client.shared.rx.request(endpoint: ChatEndpoint.query($0), connectionId: $1) }
            .map { [weak self] in self?.parseQuery($0) ?? .none }
            .asDriver(onErrorJustReturn: .none)
    
    private(set) lazy var changes: Driver<ViewChanges> = Client.shared.webSocket.response
        .map { [weak self] in self?.parseChanges(response: $0) ?? .none }
        .filter { $0 != .none }
        .asDriver(onErrorJustReturn: .none)
    
    private(set) lazy var ephemeralChanges: Driver<ViewChanges> = ephemeralSubject
        .map { [weak self] in self?.parseEphemeralChanges($0) ?? .none }
        .filter { $0 != .none }
        .asDriver(onErrorJustReturn: .none)
    
    init(channel: Channel, showStatuses: Bool = true) {
        self.channel = channel
    }
    
    init(query: Query, showStatuses: Bool = true) {
        channel = query.channel
        parseQuery(query)
    }
    
    public func item(at row: Int) -> ChatItem? {
        var row = row
        guard row >= 0 else {
            return nil
        }
        
        guard row < items.count else {
            row = items.count - row
            
            if row == 0, let message = ephemeralMessage {
                return .message(message)
            }
            
            return nil
        }
        
        return items[row]
    }
}

// MARK: - Connection

extension ChannelPresenter {
    private func parseConnection(_ connection: WebSocket.Connection, pagination: Pagination) -> (Query, String)? {
        if case .connected(let connectionId, _) = connection, let user = Client.shared.user {
            return (Query(channel: channel, members: [Member(user: user)], pagination: pagination), connectionId)
        }
        
        if !items.isEmpty {
            next = .none
            DispatchQueue.main.async { self.loadPagination.onNext(.pageSize) }
        }
        
        return nil
    }
}

// MARK: - Changes

extension ChannelPresenter {
    @discardableResult
    func parseChanges(response: WebSocket.Response) -> ViewChanges {
        guard response.channelId == channel.id else {
            return .none
        }
        
        var nextRow = items.count
        
        switch response.event {
        case .typingStart(let user):
            if channel.config.typingEventsEnabled, !user.isCurrent, (typingUsers.isEmpty || !typingUsers.contains(user)) {
                typingUsers.append(user)
                return .footerUpdated(true)
            }
        case .typingStop(let user):
            if channel.config.typingEventsEnabled, !user.isCurrent, let index = typingUsers.firstIndex(of: user) {
                typingUsers.remove(at: index)
                return .footerUpdated(true)
            }
        case .messageNew(let message, let user, _, _):
            var reloadRow: Int? = nil
            
            if let lastItem = items.last, case .message(let lastMessage) = lastItem, lastMessage.user == user {
                if lastMessage == message {
                    if items.count > 1 {
                        let lastLastItem = items[items.count - 2]
                        
                        if case .message(let lastLastMessage) = lastLastItem, lastLastMessage.user == user {
                            reloadRow = nextRow - 2
                        }
                    }
                } else {
                    reloadRow = nextRow - 1
                }
            }
            
            if let lastItem = items.last, case .message(let lastMessage) = lastItem, lastMessage == message {
                nextRow = items.count - 1
            } else {
                items.append(.message(message))
                lastMessage = message
            }
            
            var forceToScroll = false
            
            if let currentUser = Client.shared.user {
                forceToScroll = user == currentUser
            }
            
            return .itemAdded(nextRow, reloadRow, forceToScroll)
            
        case .reactionNew(let reaction, let message, _), .reactionDeleted(let reaction, let message, _):
            if let index = items.lastIndex(where: { item -> Bool in
                if case let .message(existsMessage) = item {
                    return existsMessage.id == message.id
                }
                
                return false
            }),
                case .message(let currentMessage) = items[index] {
                var message = currentMessage
                
                if reaction.isOwn {
                    var isDeleting = false
                    
                    if case .reactionDeleted = response.event {
                        isDeleting = true
                    }
                    
                    if isDeleting {
                        message.deleteFromOwnReactions(reaction)
                    } else {
                        message.addToOwnReactions(reaction)
                    }
                }
                
                items[index] = .message(message)
                return .itemUpdated(index, message)
            }
        default:
            break
        }
        
        return .none
    }
    
    private func parseEphemeralChanges(_ ephemeralType: EphemeralType) -> ViewChanges {
        if let message = ephemeralType.message {
            if ephemeralType.updated {
                return .itemUpdated(items.count, message)
            }
            
            return .itemAdded(items.count, nil, true)
        }
        
        return .itemRemoved(items.count)
    }
}

// MARK: - Load messages

extension ChannelPresenter {
    
    func loadNext() {
        if next != .none {
            load(pagination: next)
        }
    }
    
    func load(pagination: Pagination = .pageSize) {
        if items.isEmpty, pagination == .pageSize {
            next = .none
        }
        
        loadPagination.onNext(pagination)
    }
    
    @discardableResult
    private func parseQuery(_ query: Query) -> ViewChanges {
        var items = next == .none ? [ChatItem]() : self.items
        let currentCount = items.count
        
        if let first = items.first, case .loading = first {
            items.remove(at: 0)
        }
        
        var yesterdayStatusAdded = false
        var todayStatusAdded = false
        var index = 0
        let isNextPage = next != .none
        
        if !isNextPage {
            isUnread = query.isUnread
            lastMessageRead = query.lastMessageRead
        }
        
        var isNewMessagesStatusAdded = -1
        
        query.messages.forEach { message in
            if showStatuses, !yesterdayStatusAdded, message.created.isYesterday {
                yesterdayStatusAdded = true
                items.insert(.status(ChannelPresenter.statusYesterdayTitle,
                                     "at \(DateFormatter.time.string(from: message.created))",
                    false), at: index)
                index += 1
            }
            
            if showStatuses, !todayStatusAdded, message.created.isToday {
                todayStatusAdded = true
                items.insert(.status(ChannelPresenter.statusTodayTitle,
                                     "at \(DateFormatter.time.string(from: message.created))",
                    false), at: index)
                index += 1
            }
            
            items.insert(.message(message), at: index)
            index += 1
            lastMessage = message
            
            if showStatuses,
                isNewMessagesStatusAdded == -1,
                isUnread,
                let lastMessageRead = lastMessageRead,
                message.updated < lastMessageRead.lastReadDate {
                isNewMessagesStatusAdded = index
                items.insert(.status(ChannelPresenter.statusNewMessagesTitle, nil, true), at: index)
                index += 1
            }
        }
        
        if isNextPage {
            if yesterdayStatusAdded {
                removeDuplicatedStatus(statusTitle: ChannelPresenter.statusYesterdayTitle, items: &items)
            }
            
            if todayStatusAdded {
                removeDuplicatedStatus(statusTitle: ChannelPresenter.statusTodayTitle, items: &items)
            }
        }
        
        if case .limit(let limitValue) = (isNextPage ? Pagination.nextPageSize : Pagination.pageSize),
            query.messages.count == limitValue,
            let first = query.messages.first {
            next = .nextPageSize + .lessThan(first.id)
            items.insert(.loading, at: 0)
        } else {
            next = .none
            
            if isNewMessagesStatusAdded == 0 {
                items.remove(at: 0)
            }
        }
        
        channel = query.channel
        members = query.members
        self.items = items
        
        if items.count > 0 {
            if isNextPage {
                return .reloaded(max(items.count - currentCount, 0), .top)
            }
            
            return .reloaded((items.count - 1), .top)
        }
        
        return .none
    }
    
    private func removeDuplicatedStatus(statusTitle: String, items: inout [ChatItem]) {
        let searchBlock = { (item: ChatItem) -> Bool in
            if case .status(let title, _, _) = item {
                return title == statusTitle
            }
            
            return false
        }
        
        if let firstIndex = items.firstIndex(where: searchBlock),
            let lastIndex = items.lastIndex(where: searchBlock),
            firstIndex != lastIndex {
            items.remove(at: lastIndex)
        }
    }
}

// MARK: - Helpers

extension ChannelPresenter {
    public static var statusYesterdayTitle = "Yesterday"
    public static var statusTodayTitle = "Today"
    public static var statusNewMessagesTitle = "New Messages"
}

extension ChannelPresenter {
    func typingUsersText() -> String? {
        guard !typingUsers.isEmpty else {
            return nil
        }
        
        if typingUsers.count == 1, let user = typingUsers.first {
            return "\(user.name) is typing..."
        } else if typingUsers.count == 2 {
            return "\(typingUsers[0].name) and \(typingUsers[1].name) are typing..."
        } else if let user = typingUsers.first {
            return "\(user.name) and \(String(typingUsers.count - 1)) others are typing..."
        }
        
        return nil
    }
}

// MARK: - Send Message

extension ChannelPresenter {
    public func send(text: String) {
        var text = text
        
        if text.count > channel.config.maxMessageLength {
            text = String(text.prefix(channel.config.maxMessageLength))
        }
        
        guard let message = Message(text: text) else {
            return
        }
        
        Client.shared.request(endpoint: ChatEndpoint.sendMessage(message, channel), connectionId: "", ephemeralMessageCompletion)
    }
}

// MARK: - Send Reaction

extension ChannelPresenter {
    
    public func update(reactionType: String, message: Message) -> Bool {
        let add = !message.hasOwnReaction(type: reactionType)
        let endpoint: ChatEndpoint
        
        if add {
            endpoint = .addReaction(reactionType, message)
        } else {
            endpoint = .deleteReaction(reactionType, message)
        }
        
        Client.shared.request(endpoint: endpoint, connectionId: "", emptyMessageCompletion)
        
        return add
    }
}

// MARK: - Send Event

extension ChannelPresenter {
    
    public func sendEvent(isTyping: Bool) {
        if isTyping {
            if !startedTyping {
                startedTyping = true
                send(eventType: .typingStart)
            }
        } else if startedTyping {
            startedTyping = false
            send(eventType: .typingStop)
        }
    }
    
    private func send(eventType: EventType) {
        let completion: Client.Completion<EventResponse> = { _ in }
        Client.shared.request(endpoint: ChatEndpoint.sendEvent(eventType, channel), connectionId: "", completion)
    }
}

// MARK: - Ephemeral Message Actions

extension ChannelPresenter {
    
    public func dispatch(action: Attachment.Action, message: Message) {
        if action.isCancelled || action.isSend {
            ephemeralSubject.onNext((nil, true))
            
            if action.isCancelled {
                return
            }
        }
        
        let messageAction = MessageAction(channel: channel, message: message, action: action)
        Client.shared.request(endpoint: ChatEndpoint.sendMessageAction(messageAction), connectionId: "", ephemeralMessageCompletion)
    }
}

// MARK: - Supporting Structs

public struct MessageResponse: Decodable {
    let message: Message
    let reaction: Reaction?
}

public struct EventResponse: Decodable {
    let event: Event
}
