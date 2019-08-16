//
//  ChannelPresenter.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

/// A channel presenter.
public final class ChannelPresenter: Presenter<ChatItem> {
    private typealias EphemeralType = (message: Message?, updated: Bool)
    
    /// A callback type for the adding an extra data for a new message.
    public typealias MessageExtraDataCallback =
        (_ id: String, _ text: String, _ attachments: [Attachment], _ parentId: String?) -> Codable?
    
    /// A callback for the adding an extra data for a new message.
    public var messageExtraDataCallback: MessageExtraDataCallback?
    
    /// A channel (see `Channel`).
    public let channel: Channel
    /// A parent message for replies.
    public let parentMessage: Message?
    /// Query options.
    public let queryOptions: QueryOptions
    /// An edited message.
    public var editMessage: Message?
    /// Show statuses separators, e.g. Today
    public private(set) var showStatuses = true
    
    var members: [Member] = []
    private var startedTyping = false
    
    private let lastMessageMVar = MVar<Message>()
    
    /// The last parsed message from WebSocket events.
    public var lastMessage: Message? {
        return lastMessageMVar.get()
    }
    
    private var lastAddedOwnMessage: Message?
    private var lastParsedEvent: Event?
    private var lastWebSocketEventViewChanges: ViewChanges?
    
    private lazy var unreadMessageReadMVar = MVar<MessageRead>() { [weak self] in
        if $0 == nil {
            self?.unreadCountMVar.set(0)
        }
    }
    
    /// A list of typing users (see `TypingUser`).
    public private(set) var typingUsers: [TypingUser] = []
    private var messageReadsToMessageId: [MessageRead: String] = [:]
    private let ephemeralSubject = BehaviorSubject<EphemeralType>(value: (nil, false))
    private let isReadSubject = PublishSubject<Void>()
    private let unreadCountMVar = MVar(0)
    
    /// Check if the channel has unread messages.
    public var isUnread: Bool {
        return channel.config.readEventsEnabled && unreadMessageReadMVar.get() != nil
    }
    
    /// A number of unread messages in the channel.
    public var unreadCount: Int {
        return channel.config.readEventsEnabled ? unreadCountMVar.get(defaultValue: 0) : 0
    }
    
    /// Check if the channel has ephemeral message, e.g. Giphy preview.
    public var hasEphemeralMessage: Bool { return ephemeralMessage != nil }
    /// An ephemeral message, e.g. Giphy preview.
    public var ephemeralMessage: Message? { return (try? ephemeralSubject.value())?.message }
    
    /// Check if the user can reply (create a thread) to a message.
    public var canReply: Bool {
        return parentMessage == nil && channel.config.repliesEnabled
    }
    
    /// An observable view changes (see `ViewChanges`).
    public private(set) lazy var changes = Driver.merge(parentMessage == nil ? channelRequest : replyRequest,
                                                        webSocketChanges,
                                                        ephemeralChanges,
                                                        connectionErrors)
    
    private lazy var channelRequest: Driver<ViewChanges> = prepareRequest()
        .filter { [weak self] in $0 != .none && self?.parentMessage == nil }
        .flatMapLatest { [weak self] in (self?.channel.query(pagination: $0) ?? .empty()).retry(3) }
        .map { [weak self] in self?.parseResponse($0) ?? .none }
        .filter { $0 != .none }
        .map { [weak self] in self?.mapWithEphemeralMessage($0) ?? .none }
        .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    
    private lazy var replyRequest: Driver<ViewChanges> = prepareRequest()
        .filter { [weak self] _ in self?.parentMessage != nil }
        .flatMapLatest { [weak self] in (self?.parentMessage?.replies(pagination: $0) ?? .empty()).retry(3) }
        .map { [weak self] in self?.parseReplies($0) ?? .none }
        .filter { $0 != .none }
        .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    
    private lazy var webSocketChanges: Driver<ViewChanges> = channel.onEvent()
        .map { [weak self] in self?.parseChanges(event: $0) ?? .none }
        .filter { $0 != .none }
        .map { [weak self] in self?.mapWithEphemeralMessage($0) ?? .none }
        .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    
    private lazy var ephemeralChanges: Driver<ViewChanges> = ephemeralSubject
        .skip(1)
        .map { [weak self] in self?.parseEphemeralChanges($0) ?? .none }
        .filter { $0 != .none }
        .asDriver { Driver.just(ViewChanges.error(AnyError(error: $0))) }
    
    /// Uploader for images and files.
    public private(set) lazy var uploader = Uploader()
    
    /// An observable updates for the Read event.
    public private(set) lazy var isReadUpdates = isReadSubject.asDriver(onErrorJustReturn: ())
    
    /// Init a presenter with a given channel.
    ///
    /// - Parameters:
    ///     - channel: a channel
    ///     - parentMessage: a parent message for replies
    ///     - showStatuses: shows statuses separators, e.g. Today
    public init(channel: Channel,
                parentMessage: Message? = nil,
                queryOptions: QueryOptions = .all,
                showStatuses: Bool = true) {
        self.channel = channel
        self.parentMessage = parentMessage
        self.queryOptions = queryOptions
        self.showStatuses = showStatuses
        super.init(pageSize: .messagesPageSize)
    }
    
    /// Init a presenter with a given channel query.
    ///
    /// - Parameters:
    ///     - query: a channel query result with messages
    ///     - showStatuses: shows statuses separators, e.g. Today
    public init(response: ChannelResponse, queryOptions: QueryOptions, showStatuses: Bool = true) {
        channel = response.channel
        parentMessage = nil
        self.queryOptions = queryOptions
        self.showStatuses = showStatuses
        super.init(pageSize: .messagesPageSize)
        parseResponse(response)
    }
}

// MARK: - Changes

extension ChannelPresenter {
    
    @discardableResult
    func parseChanges(event: Event) -> ViewChanges {
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
            
        case .messageNew(let message, _, _, _, _, _):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
            if channel.config.readEventsEnabled {
                if let lastMessage = lastMessageMVar.get() {
                    unreadMessageReadMVar.set(MessageRead(user: lastMessage.user, lastReadDate: lastMessage.updated))
                } else {
                    unreadMessageReadMVar.set(MessageRead(user: message.user, lastReadDate: message.updated))
                }
                
                unreadCountMVar += 1
            }
            
            let nextRow = items.count
            let reloadRow: Int? = items.last?.message?.user == message.user ? nextRow - 1 : nil
            appendOrUpdateMessageItem(message)
            let viewChanges = ViewChanges.itemAdded(nextRow, reloadRow, message.user.isCurrent, items)
            lastWebSocketEventViewChanges = viewChanges
            Notifications.shared.showIfNeeded(newMessage: message, in: channel)
            
            return viewChanges
            
        case .messageUpdated(let message, _),
             .messageDeleted(let message, _):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
            if let index = items.lastIndex(whereMessageId: message.id) {
                appendOrUpdateMessageItem(message, at: index)
                let viewChanges = ViewChanges.itemUpdated([index], [message], items)
                lastWebSocketEventViewChanges = viewChanges
                return viewChanges
            }
            
        case .reactionNew(let reaction, let message, _, _), .reactionDeleted(let reaction, let message, _, _):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
            if let index = items.lastIndex(whereMessageId: message.id) {
                var message = message
                
                if reaction.isOwn, let currentMessage = items[index].message {
                    if case .reactionDeleted = event {
                        message.deleteFromOwnReactions(reaction, reactions: currentMessage.ownReactions)
                    } else {
                        message.addToOwnReactions(reaction, reactions: currentMessage.ownReactions)
                    }
                }
                
                appendOrUpdateMessageItem(message, at: index)
                let viewChanges = ViewChanges.itemUpdated([index], [message], items)
                lastWebSocketEventViewChanges = viewChanges
                return viewChanges
            }
            
        case .messageRead(let messageRead, _):
            guard channel.config.readEventsEnabled,
                let currentUser = User.current,
                messageRead.user != currentUser,
                let lastAddedOwnMessage = lastAddedOwnMessage,
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
            
            return .itemUpdated(rows, messages, items)
            
        default:
            break
        }
        
        return .none
    }
    
    private func appendOrUpdateMessageItem(_ message: Message, at index: Int = -1) {
        lastMessageMVar.set(message)
        
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
        case .none, .footerUpdated, .error:
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
    private func parseResponse(_ query: ChannelResponse) -> ViewChanges {
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
    
    private func parseReplies(_ messagesResponse: MessagesResponse) -> ViewChanges {
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
        guard let currentUser = User.current else {
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
                lastAddedOwnMessage = message
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
    /// A title for the yesterday separator.
    public static var statusYesterdayTitle = "Yesterday"
    /// A title for the today separator.
    public static var statusTodayTitle = "Today"
}

extension ChannelPresenter {
    
    private func filterInvalidatedTypingUsers() -> Bool {
        let count = typingUsers.count
        typingUsers = typingUsers.filter { $0.started.timeIntervalSinceNow > -TypingUser.timeout }
        return typingUsers.count != count
    }
    
    /// Creates a text for users typing.
    ///
    /// - Returns: a text of users typing, e.g. "<UserName> is typing...", "User1 and 5 others are typing..."
    public func typingUsersText() -> String? {
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
    
    /// Create a message by sending a text.
    ///
    /// - Parameters:
    ///     - text: a message text
    ///     - completion: a completion blocks
    public func send(text: String) -> Observable<MessageResponse> {
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
        
        editMessage = nil
        
        let message = Message(id: messageId,
                              text: text,
                              attachments: attachments,
                              extraData: extraData,
                              parentId: parentId,
                              showReplyInChannel: false)
        
        return channel.send(message: message)
            .do(onNext: { [weak self] in self?.updateEphemeralMessage($0.message) })
            .observeOn(MainScheduler.instance)
    }
    
    private func updateEphemeralMessage(_ message: Message) {
        if message.type == .ephemeral {
            ephemeralSubject.onNext((message, hasEphemeralMessage))
        }
    }
}

// MARK: - Send Event

extension ChannelPresenter {
    /// Send a typing event.
    public func sendEvent(isTyping: Bool) -> Observable<Event> {
        guard parentMessage == nil else {
            return .empty()
        }
        
        if isTyping {
            if !startedTyping {
                startedTyping = true
                return channel.send(eventType: .typingStart).observeOn(MainScheduler.instance)
            }
        } else if startedTyping {
            startedTyping = false
            return channel.send(eventType: .typingStop).observeOn(MainScheduler.instance)
        }
        
        return .empty()
    }
    
    /// Send Read event if the app is active.
    ///
    /// - Returns: an observable completion.
    public func markReadIfPossible() -> Observable<Void> {
        guard let oldUnreadMessageRead = unreadMessageReadMVar.get() else {
            Client.shared.logger?.log("🎫", "Skip read.")
            return .empty()
        }
        
        unreadMessageReadMVar.set(nil)
        
        return Observable.just(())
            .subscribeOn(MainScheduler.instance)
            .filter { UIApplication.shared.appState == .active }
            .do(onNext: { Client.shared.logger?.log("🎫", "Send Message Read. Unread from \(oldUnreadMessageRead.lastReadDate)") })
            .flatMap { [weak self] in self?.channel.markRead() ?? .empty() }
            .do(onNext: { [weak self] _ in
                self?.updateUnreadMessageRead(nil)
                self?.isReadSubject.onNext(())
                Client.shared.logger?.log("🎫", "Message Read done.")
                }, onError: { [weak self] error in
                    self?.updateUnreadMessageRead(oldUnreadMessageRead)
                    self?.isReadSubject.onError(error)
                    ClientLogger.log("🎫", error, message: "Send Message Read error.")
            })
            .map { _ in Void() }
    }
    
    private func updateUnreadMessageRead(_ messageRead: MessageRead?) {
        unreadMessageReadMVar.set(messageRead)
        updateUnreadCount()
    }
}

// MARK: - Ephemeral Message Actions

extension ChannelPresenter {
    /// Dispatch an ephemeral message action, e.g. shuffle, send.
    public func dispatch(action: Attachment.Action, message: Message) -> Observable<MessageResponse> {
        if action.isCancelled || action.isSend {
            ephemeralSubject.onNext((nil, true))
            
            if action.isCancelled {
                return .empty()
            }
        }
        
        return channel.send(action: action, for: message)
            .do(onNext: { [weak self] in self?.updateEphemeralMessage($0.message) })
            .observeOn(MainScheduler.instance)
    }
}

/// A typing user.
public struct TypingUser: Hashable {
    /// A time interval for a users typing timeout.
    public static let timeout: TimeInterval = 30
    
    /// A typiong user.
    public let user: User
    /// A date when the user started typing.
    public let started = Date()
    
    public static func == (lhs: TypingUser, rhs: TypingUser) -> Bool {
        return lhs.user == rhs.user
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(user)
    }
}
