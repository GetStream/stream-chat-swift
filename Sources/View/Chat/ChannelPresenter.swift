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
    
    private(set) var lastMessage: Message?
    private(set) var isUnread = false
    private(set) var lastMessageRead: MessageRead?
    private(set) var typingUsers: [User] = []
    private let ephemeralSubject = BehaviorSubject<EphemeralType>(value: (nil, false))
    private let isReadSubject = PublishSubject<Void>()
    
    public var hasEphemeralMessage: Bool { return ephemeralMessage != nil }
    public var ephemeralMessage: Message? { return (try? ephemeralSubject.value())?.message }
    
    public var canReply: Bool {
        return parentMessage == nil && channel.config.repliesEnabled
    }
    
    private lazy var lazyRequest = request()
    
    private(set) lazy var channelRequest: Driver<ViewChanges> = lazyRequest
        .map { [weak self] in self?.channelEndpoint(pagination: $0) }
        .unwrap()
        .flatMapLatest { Client.shared.rx.request(endpoint: $0) }
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
            
            if channel.config.typingEventsEnabled, !user.isCurrent, (typingUsers.isEmpty || !typingUsers.contains(user)) {
                typingUsers.append(user)
                return .footerUpdated(true)
            }
        case .typingStop(let user):
            guard parentMessage == nil else {
                return .none
            }
            
            if channel.config.typingEventsEnabled, !user.isCurrent, let index = typingUsers.firstIndex(of: user) {
                typingUsers.remove(at: index)
                return .footerUpdated(true)
            }
        case .messageNew(let message, let user, _, _):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
            var reloadRow: Int? = nil
            let last = findLastMessage()
            
            if let last = last, last.message.user == user {
                // Double parsing issue: avoid doublications.
                if last.message == message {
                    if items.count > 1, let prev = findLastMessage(before: last.index), prev.message.user == user {
                        reloadRow = prev.index
                    }
                } else {
                    reloadRow = last.index
                }
            }
            
            if let last = last, last.message == message {
                nextRow = last.index
            } else {
                isUnread = channel.config.readEventsEnabled
                lastMessage = message
                items.append(.message(message))
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
            
            if let index = items.lastIndex(where: { item -> Bool in
                if case .message(let itemMessage) = item, itemMessage.id == message.id {
                    return true
                }
                return false
            }) {
                items[index] = .message(message)
                return .itemUpdated(index, message, items)
            }
            
        case .reactionNew(let reaction, let message, _), .reactionDeleted(let reaction, let message, _):
            guard shouldMessageEventBeHandled(message) else {
                return .none
            }
            
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
                return .itemUpdated(index, message, items)
            }
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
    
    private func findLastMessage(before beforeIndex: Int = .max) -> (index: Int, message: Message)? {
        guard !items.isEmpty else {
            return nil
        }
        
        for (index, item) in items.enumerated().reversed() where index < beforeIndex  {
            if case .message(let message) = item {
                return (index, message)
            }
        }
        
        return nil
    }
    
    private func parseEphemeralChanges(_ ephemeralType: EphemeralType) -> ViewChanges {
        if let message = ephemeralType.message {
            var items = self.items
            let row = items.count
            items.append(.message(message))
            
            if ephemeralType.updated {
                return .itemUpdated(row, message, items)
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
            items.append(.message(ephemeralMessage))
            return .reloaded(row, items)
            
        case let .itemAdded(row, reloadRow, forceToScroll, items):
            var items = items
            items.append(.message(ephemeralMessage))
            return .itemAdded(row, reloadRow, forceToScroll, items)
            
        case let .itemUpdated(row, message, items):
            var items = items
            items.append(.message(ephemeralMessage))
            return .itemUpdated(row, message, items)
            
        case let .itemRemoved(row, items):
            var items = items
            items.append(.message(ephemeralMessage))
            return .itemRemoved(row, items)
            
        case let .itemMoved(fromRow, toRow, items):
            var items = items
            items.append(.message(ephemeralMessage))
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
        
        if channel.config.readEventsEnabled, !isNextPage {
            isUnread = query.isUnread
            lastMessageRead = query.lastMessageRead
        }
        
        let currentCount = items.count
        parse(query.messages, to: &items, isNextPage: isNextPage)
        self.items = items
        channel = query.channel
        members = query.members
        
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
            items.append(.message(parentMessage))
            items.append(.status("Start of thread", nil, false))
        }
        
        if let loadingIndex = items.firstIndex(of: .loading) {
            items.remove(at: loadingIndex)
        }
        
        let currentCount = items.count
        parse(messagesResponse.messages, to: &items, startIndex: 2, isNextPage: isNextPage)
        self.items = items
        
        return isNextPage ? .reloaded(max(items.count - currentCount - 1, 0), items) : .reloaded((items.count - 1), items)
    }
    
    private func parse(_ messages: [Message],
                       to items: inout [ChatItem],
                       startIndex: Int = 0,
                       isNextPage: Bool) {
        var isNewMessagesStatusAdded = -1
        var yesterdayStatusAdded = false
        var todayStatusAdded = false
        var index = startIndex
        
        messages.forEach { message in
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
                channel.config.readEventsEnabled,
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
        
        if messages.count == (isNextPage ? Pagination.messagesNextPageSize : pageSize).limit,
            let first = messages.first {
            next = .messagesNextPageSize + .lessThan(first.id)
            items.insert(.loading, at: startIndex)
        } else {
            next = pageSize
        }
        
        if isNewMessagesStatusAdded == startIndex {
            items.remove(at: startIndex)
        }
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

// MARK: - Send/Delete Message

extension ChannelPresenter {
    
    public func send(text: String, completion: @escaping () -> Void) {
        var text = text
        
        if text.count > channel.config.maxMessageLength {
            text = String(text.prefix(channel.config.maxMessageLength))
        }
        
        let messageId = editMessage?.id ?? ""
        let attachments = uploader.items.compactMap({ $0.attachment })
        let parentId = parentMessage?.id
        var extraData: ExtraData? = nil
        
        if let messageExtraDataCallback = messageExtraDataCallback,
            let data = messageExtraDataCallback(messageId, text, attachments, parentId) {
            extraData = ExtraData(data)
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
    
    public func update(reactionType: String, message: Message) -> Bool {
        let add = !message.hasOwnReaction(type: reactionType)
        let endpoint: ChatEndpoint
        
        if add {
            endpoint = .addReaction(reactionType, message)
        } else {
            endpoint = .deleteReaction(reactionType, message)
        }
        
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
        Client.shared.request(endpoint: ChatEndpoint.sendEvent(eventType, channel), emptyEventCompletion)
    }
    
    func sendReadIfPossible() {
        guard channel.config.readEventsEnabled, isUnread else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            if UIApplication.shared.appState == .active {
                self?.sendRead()
            }
        }
    }
    
    private func sendRead() {
        isUnread = false
        
        let emptyEventCompletion: Client.Completion<EventResponse> = { [weak self] result in
            if let self = self {
                if let error = result.error {
                    self.isUnread = false
                    self.isReadSubject.onError(error)
                } else {
                    self.isUnread = false
                    self.lastMessageRead = nil
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
