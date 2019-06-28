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

public final class ChannelPresenter: Presenter<ChatItem> {
    private typealias EphemeralType = (message: Message?, updated: Bool)
    public typealias Completion = (_ error: Error?) -> Void
    
    public typealias MessageExtraDataCallback =
        (_ id: String, _ text: String, _ attachments: [Attachment], _ parentId: String?) -> Codable?

    private let emptyMessageCompletion: Client.Completion<MessageResponse> = { _ in }
    private let emptyEventCompletion: Client.Completion<EventResponse> = { _ in }
    public var messageExtraDataCallback: MessageExtraDataCallback?
    
    public private(set) var channel: Channel
    public private(set) var parentMessage: Message?
    public var editMessage: Message?
    public private(set) var showStatuses = true
    
    var members: [Member] = []
    private var startedTyping = false
    
    private let lastMessageMVar = MVar<Message>()
    
    public var lastMessage: Message? {
        return lastMessageMVar.get()
    }
    
    private var lastOwnMessage: Message?
    
    private lazy var unreadMessageReadMVar = MVar<MessageRead>() { [weak self] in
        if $0 == nil {
            self?.unreadCountMVar.set(0)
        }
    }
    
    private(set) var typingUsers: [TypingUser] = []
    private var messageReadsToMessageId: [MessageRead: String] = [:]
    private let ephemeralSubject = BehaviorSubject<EphemeralType>(value: (nil, false))
    private let isReadSubject = PublishSubject<Void>()
    private let unreadCountMVar = MVar(0)
    
    public var isUnread: Bool {
        return channel.config.readEventsEnabled && unreadMessageReadMVar.get() != nil
    }
    
    public var unreadCount: Int {
        return channel.config.readEventsEnabled ? unreadCountMVar.get(defaultValue: 0) : 0
    }
    
    public var hasEphemeralMessage: Bool { return ephemeralMessage != nil }
    public var ephemeralMessage: Message? { return (try? ephemeralSubject.value())?.message }
    
    public var canReply: Bool {
        return parentMessage == nil && channel.config.repliesEnabled
    }
    
    private lazy var lazyRequest = request()
    
    private(set) lazy var channelRequest: Driver<ViewChanges> = lazyRequest
        .map { [weak self] in self?.channelEndpoint(pagination: $0) }
        .unwrap()
        .flatMapLatest { Client.shared.rx.request(endpoint: $0).retry(3) }
        .map { [weak self] in self?.parseQuery($0) ?? .none }
        .filter { $0 != .none }
        .map { [weak self] in self?.mapWithEphemeralMessage($0) ?? .none }
        .asDriver(onErrorJustReturn: .none)
    
    private(set) lazy var replyRequest: Driver<ViewChanges> = lazyRequest
        .map { [weak self] in self?.replyEndpoint(pagination: $0) }
        .unwrap()
        .flatMapLatest { Client.shared.rx.request(endpoint: $0) }
        .map { [weak self] in self?.parseReply($0) ?? .none }
        .filter { $0 != .none }
        .asDriver(onErrorJustReturn: .none)
    
    private(set) lazy var changes: Driver<ViewChanges> = Client.shared.webSocket.response
        .map { [weak self] in self?.parseChanges(response: $0) ?? .none }
        .filter { $0 != .none }
        .map { [weak self] in self?.mapWithEphemeralMessage($0) ?? .none }
        .asDriver(onErrorJustReturn: .none)
    
    private(set) lazy var ephemeralChanges: Driver<ViewChanges> = ephemeralSubject
        .skip(1)
        .map { [weak self] in self?.parseEphemeralChanges($0) ?? .none }
        .filter { $0 != .none }
        .asDriver(onErrorJustReturn: .none)
    
    private(set) lazy var uploader = Uploader(channel: channel)
    private(set) lazy var isReadUpdates = isReadSubject.asDriver(onErrorJustReturn: ())
    
    public init(channel: Channel, parentMessage: Message? = nil, showStatuses: Bool = true) {
        self.channel = channel
        self.parentMessage = parentMessage
        self.showStatuses = showStatuses
        super.init(pageSize: .messagesPageSize)
    }
    
    public init(query: ChannelQuery, showStatuses: Bool = true) {
        self.showStatuses = showStatuses
        channel = query.channel
        super.init(pageSize: .messagesPageSize)
        parseQuery(query)
    }
}

// MARK: - Connection

extension ChannelPresenter {
    
    private func channelEndpoint(pagination: Pagination) -> ChatEndpoint? {
        guard parentMessage == nil, let user = Client.shared.user else {
            return nil
        }
        
        return .channel(ChannelQuery(channel: channel, members: [Member(user: user)], pagination: pagination))
    }
    
    private func replyEndpoint(pagination: Pagination) -> ChatEndpoint? {
        if let parentMessage = parentMessage {
            return .thread(parentMessage, pagination)
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
        case .typingStop(let user):
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
        case .messageNew(let message, let user, _, _):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
            var reloadRow: Int? = nil
            let last = items.findLastMessage()
            
            if let last = last, last.message.user == user {
                // Double parsing issue: avoid duplications.
                if last.message == message {
                    if items.count > 1, let prev = items.findLastMessage(before: last.index), prev.message.user == user {
                        reloadRow = prev.index
                    }
                } else {
                    reloadRow = last.index
                }
            }
            
            if let last = last, last.message == message {
                nextRow = last.index
            } else {
                if channel.config.readEventsEnabled, let currentUser = Client.shared.user, currentUser != message.user {
                    if let lastMessage = lastMessageMVar.get() {
                        unreadMessageReadMVar.set(MessageRead(user: lastMessage.user, lastReadDate: lastMessage.updated))
                    } else {
                        unreadMessageReadMVar.set(MessageRead(user: message.user, lastReadDate: message.updated))
                    }
                    
                    unreadCountMVar += 1
                }
                
                if message.isOwn {
                    lastOwnMessage = message
                }
                
                lastMessageMVar.set(message)
                items.append(.message(message, []))
                Notifications.shared.showIfNeeded(newMessage: message, in: channel)
            }
            
            var forceToScroll = false
            
            if let currentUser = Client.shared.user {
                forceToScroll = user == currentUser
            }
            
            return .itemAdded(nextRow, reloadRow, forceToScroll, items)
            
        case .messageUpdated(let message),
             .messageDeleted(let message):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
            if let index = items.lastIndex(whereMessageId: message.id) {
                items[index] = .message(message, items[index].messageReadUsers)
                return .itemUpdated([index], [message], items)
            }
            
        case .reactionNew(let reaction, let message, _), .reactionDeleted(let reaction, let message, _):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
            if let index = items.lastIndex(whereMessageId: message.id) {
                var message = message
                
                if reaction.isOwn, let currentMessage = items[index].message {
                    if case .reactionDeleted = response.event {
                        message.deleteFromOwnReactions(reaction, reactions: currentMessage.ownReactions)
                    } else {
                        message.addToOwnReactions(reaction, reactions: currentMessage.ownReactions)
                    }
                }
                
                items[index] = .message(message, items[index].messageReadUsers)
                return .itemUpdated([index], [message], items)
            }
            
        case .messageRead(let messageRead):
            guard channel.config.readEventsEnabled,
                let currentUser = Client.shared.user,
                messageRead.user != currentUser,
                let lastOwnMessage = lastOwnMessage,
                lastOwnMessage.created <= messageRead.lastReadDate,
                let lastOwnMessageIndex = items.lastIndex(whereMessageId: lastOwnMessage.id) else {
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
                items[lastOwnMessageIndex] = .message(lastOwnMessage, readUsers)
                rows.append(lastOwnMessageIndex)
                messages.append(lastOwnMessage)
                messageReadsToMessageId[messageRead] = lastOwnMessage.id
            }
            
            return .itemUpdated(rows, messages, items)
            
        default:
            break
        }
        
        return .none
    }
    
    private func shouldMessageEventBeHandled(_ message: Message) -> Bool {
        guard let parentMessage = parentMessage else {
            return message.parentId == nil
        }
        
        return message.parentId == parentMessage.id || message.id == parentMessage.id
    }
    
    private func parseEphemeralChanges(_ ephemeralType: EphemeralType) -> ViewChanges {
        if let message = ephemeralType.message {
            var items = self.items
            let row = items.count
            items.append(.message(message, []))
            
            if ephemeralType.updated {
                return .itemUpdated([row], [message], items)
            }
            
            return .itemAdded(row, nil, true, items)
        }
        
        return .itemRemoved(items.count, items)
    }
    
    private func mapWithEphemeralMessage(_ changes: ViewChanges) -> ViewChanges {
        guard let ephemeralType = try? ephemeralSubject.value(), let ephemeralMessage = ephemeralType.message else {
            return changes
        }
        
        switch changes {
        case .none, .footerUpdated:
            return changes
            
        case let .reloaded(row, items):
            var items = items
            items.append(.message(ephemeralMessage, []))
            return .reloaded(row, items)
            
        case let .itemAdded(row, reloadRow, forceToScroll, items):
            var items = items
            items.append(.message(ephemeralMessage, []))
            return .itemAdded(row, reloadRow, forceToScroll, items)
            
        case let .itemUpdated(row, message, items):
            var items = items
            items.append(.message(ephemeralMessage, []))
            return .itemUpdated(row, message, items)
            
        case let .itemRemoved(row, items):
            var items = items
            items.append(.message(ephemeralMessage, []))
            return .itemRemoved(row, items)
            
        case let .itemMoved(fromRow, toRow, items):
            var items = items
            items.append(.message(ephemeralMessage, []))
            return .itemMoved(fromRow: fromRow, toRow: toRow, items)
        }
    }
}

// MARK: - Load messages

extension ChannelPresenter {
    
    @discardableResult
    private func parseQuery(_ query: ChannelQuery) -> ViewChanges {
        let isNextPage = next != pageSize
        var items = isNextPage ? self.items : []
        
        if let first = items.first, first.isLoading {
            items.removeFirst()
        }
        
        if channel.config.readEventsEnabled {
            unreadMessageReadMVar.set(query.unreadMessageRead)
            
            if !isNextPage {
                messageReadsToMessageId = [:]
            }
        }
        
        let currentCount = items.count
        let messageReads = channel.config.readEventsEnabled ? query.messageReads : []
        parse(query.messages, messageReads: messageReads, to: &items, isNextPage: isNextPage)
        self.items = items
        channel = query.channel
        members = query.members
        
        if channel.config.readEventsEnabled {
            updateUnreadCount()
        }
        
        if self.items.count > 0 {
            if isNextPage {
                return .reloaded(max(items.count - currentCount - 1, 0), items)
            }
            
            return .reloaded((items.count - 1), items)
        }
        
        return .none
    }
    
    private func parseReply(_ messagesResponse: MessagesResponse) -> ViewChanges {
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
        parse(messagesResponse.messages, to: &items, startIndex: 2, isNextPage: isNextPage)
        self.items = items
        
        return isNextPage ? .reloaded(max(items.count - currentCount - 1, 0), items) : .reloaded((items.count - 1), items)
    }
    
    private func parse(_ messages: [Message],
                       messageReads: [MessageRead] = [],
                       to items: inout [ChatItem],
                       startIndex: Int = 0,
                       isNextPage: Bool) {
        guard let currentUser = Client.shared.user else {
            return
        }
        
        var yesterdayStatusAdded = false
        var todayStatusAdded = false
        var index = startIndex
        var ownMessagesIndexes: [Int] = []
        
        // Add chat items for messages.
        messages.enumerated().forEach { messageIndex, message in
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
            
            if message.isOwn {
                lastOwnMessage = message
                ownMessagesIndexes.append(index)
            }
            
            lastMessageMVar.set(message)
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
                removeDuplicatedStatus(statusTitle: ChannelPresenter.statusYesterdayTitle, items: &items)
            }
            
            if todayStatusAdded {
                removeDuplicatedStatus(statusTitle: ChannelPresenter.statusTodayTitle, items: &items)
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
    
    private func updateUnreadCount() {
        guard let unreadMessageRead = unreadMessageReadMVar.get() else {
            unreadCountMVar.set(0)
            return
        }
        
        var count = 0
        
        for item in items.reversed() {
            if let message = item.message {
                if message.created > unreadMessageRead.lastReadDate {
                    count += 1
                } else {
                    break
                }
            }
        }
        
        unreadCountMVar.set(count)
    }
}

// MARK: - Helpers

extension ChannelPresenter {
    public static var statusYesterdayTitle = "Yesterday"
    public static var statusTodayTitle = "Today"
}

extension ChannelPresenter {
    
    private func filterInvalidatedTypingUsers() -> Bool {
        let count = typingUsers.count
        typingUsers = typingUsers.filter { $0.started.timeIntervalSinceNow > -TypingUser.timeout }
        return typingUsers.count != count
    }
    
    func typingUsersText() -> String? {
        guard !typingUsers.isEmpty else {
            return nil
        }
        
        if typingUsers.count == 1, let typingUser = typingUsers.first {
            return "\(typingUser.user.name) is typing..."
        } else if typingUsers.count == 2 {
            return "\(typingUsers[0].user.name) and \(typingUsers[1].user.name) are typing..."
        } else if let typingUser = typingUsers.first {
            return "\(typingUser.user.name) and \(String(typingUsers.count - 1)) others are typing..."
        }
        
        return nil
    }
}

// MARK: - Send/Delete Message

extension ChannelPresenter {
    
    public func send(text: String, completion: @escaping () -> Void) {
        var text = text
        
        if text.count > channel.config.maxMessageLength {
            text = String(text.prefix(channel.config.maxMessageLength))
        }
        
        let messageId = editMessage?.id ?? ""
        var attachments = uploader.items.compactMap({ $0.attachment })
        let parentId = parentMessage?.id
        var extraData: ExtraData? = nil
        
        if let messageExtraDataCallback = messageExtraDataCallback,
            let data = messageExtraDataCallback(messageId, text, attachments, parentId) {
            extraData = ExtraData(data)
        }
        
        if attachments.isEmpty, let editMessage = editMessage, !editMessage.attachments.isEmpty {
            attachments = editMessage.attachments
        }
        
        guard let message = Message(id: messageId,
                                    text: text,
                                    attachments: attachments,
                                    extraData: extraData,
                                    parentId: parentId,
                                    showReplyInChannel: false) else {
            return
        }
        
        editMessage = nil
        Client.shared.request(endpoint: ChatEndpoint.sendMessage(message, channel), messageCompletion(completion))
    }
    
    public func delete(message: Message) {
        Client.shared.request(endpoint: ChatEndpoint.deleteMessage(message), emptyMessageCompletion)
    }
    
    private func messageCompletion(_ completion: @escaping () -> Void) -> Client.Completion<MessageResponse> {
        return { [weak self] result in
            if let self = self, let response = try? result.get(), response.message.type == .ephemeral {
                self.ephemeralSubject.onNext((response.message, self.hasEphemeralMessage))
            }
            
            DispatchQueue.main.async(execute: completion)
        }
    }
}

// MARK: - Send Reaction

extension ChannelPresenter {
    
    public func update(reactionType: String, messageId: String) -> Bool? {
        guard let index = items.lastIndex(whereMessageId: messageId), let message = items[index].message else {
            return nil
        }
        
        let add = !message.hasOwnReaction(type: reactionType)
        let endpoint = add ? ChatEndpoint.addReaction(reactionType, message) : .deleteReaction(reactionType, message)
        Client.shared.request(endpoint: endpoint, emptyMessageCompletion)
        
        return add
    }
}

// MARK: - Send Event

extension ChannelPresenter {
    
    public func sendEvent(isTyping: Bool) {
        guard parentMessage == nil else {
            return
        }
        
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
        Client.shared.logger?.log("🎫", eventType.rawValue)
        Client.shared.request(endpoint: ChatEndpoint.sendEvent(eventType, channel), emptyEventCompletion)
    }
    
    func sendReadIfPossible() {
        guard isUnread, UIApplication.shared.appState == .active else {
            return
        }
        
        let oldUnreadMessageRead = unreadMessageReadMVar.get()
        Client.shared.logger?.log("🎫", "Send Read. Unread from \(oldUnreadMessageRead?.lastReadDate.description ?? "false")")
        unreadMessageReadMVar.set(nil)
        
        DispatchQueue.main.async { [weak self] in
            if UIApplication.shared.appState == .active {
                self?.sendRead(oldUnreadMessageRead: oldUnreadMessageRead)
            } else {
                self?.unreadMessageReadMVar.set(oldUnreadMessageRead)
                self?.updateUnreadCount()
            }
        }
    }
    
    private func sendRead(oldUnreadMessageRead: MessageRead?) {
        let emptyEventCompletion: Client.Completion<EventResponse> = { [weak self] result in
            if let self = self {
                if let error = result.error {
                    self.unreadMessageReadMVar.set(oldUnreadMessageRead)
                    self.updateUnreadCount()
                    self.isReadSubject.onError(error)
                } else {
                    self.unreadMessageReadMVar.set(nil)
                    Client.shared.logger?.log("🎫", "Read done.")
                    self.isReadSubject.onNext(())
                }
            }
        }
        
        Client.shared.request(endpoint: ChatEndpoint.sendRead(channel), emptyEventCompletion)
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
        Client.shared.request(endpoint: ChatEndpoint.sendMessageAction(messageAction), messageCompletion({}))
    }
}

// MARK: - Supporting Structs

public struct MessageResponse: Decodable {
    let message: Message
    let reaction: Reaction?
}

public struct MessagesResponse: Decodable {
    let messages: [Message]
}

public struct EventResponse: Decodable {
    let event: Event
}

public struct FileUploadResponse: Decodable {
    let file: URL
}

public struct TypingUser: Equatable, Hashable {
    static let timeout: TimeInterval = 30
    
    let user: User
    let started = Date()
    
    public static func == (lhs: TypingUser, rhs: TypingUser) -> Bool {
        return lhs.user == rhs.user
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(user)
    }
}
