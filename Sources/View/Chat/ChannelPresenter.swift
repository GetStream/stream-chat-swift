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

public enum ChannelChanges: Equatable {
    case none
    case reloaded(_ row: Int, UITableView.ScrollPosition)
    case itemAdded(_ row: Int, _ reloadRow: Int?, _ forceToScroll: Bool)
    case itemUpdated(_ row: Int, Message)
    case itemRemoved(_ row: Int)
    case updateFooter(_ isUsersTyping: Bool)
}

public final class ChannelPresenter {
    public typealias Completion = (_ error: Error?) -> Void
    private typealias EphemeralType = (message: Message?, updated: Bool)
    
    public private(set) var channel: Channel
    var members: [Member] = []
    private var next: Pagination = .none
    private var startedTyping = false
    
    private(set) var items: [ChatItem] = []
    private(set) var typingUsers: [User] = []
    private let loadPagination = PublishSubject<Pagination>()
    private let ephemeralSubject = BehaviorSubject<EphemeralType>(value: (nil, false))
    
    public var hasEphemeralMessage: Bool {
        return ephemeralMessage != nil
    }
    
    public var ephemeralMessage: Message? {
        return (try? ephemeralSubject.value())?.message
    }
    
    private(set) lazy var loading: Driver<ChannelChanges> =
        Observable.combineLatest(Client.shared.webSocket.connection, loadPagination.asObserver())
            .map { [weak self] in self?.parseConnection($0, pagination: $1) }
            .unwrap()
            .flatMapLatest { Client.shared.rx.request(endpoint: ChatEndpoint.query($0), connectionId: $1) }
            .map { [weak self] in self?.parseQuery($0) ?? .none }
            .asDriver(onErrorJustReturn: .none)
    
    private(set) lazy var changes: Driver<ChannelChanges> = Client.shared.webSocket.response
        .map { [weak self] in self?.parseChanges(response: $0) ?? .none }
        .filter { $0 != .none }
        .asDriver(onErrorJustReturn: .none)
    
    private(set) lazy var ephemeralChanges: Driver<ChannelChanges> = ephemeralSubject
        .map { [weak self] in self?.parseEphemeralChanges($0) ?? .none }
        .filter { $0 != .none }
        .asDriver(onErrorJustReturn: .none)
    
    init(channel: Channel) {
        self.channel = channel
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
    private func parseChanges(response: WebSocket.Response) -> ChannelChanges {
        guard response.channelId == channel.id else {
            return .none
        }
        
        let nextRow = items.count
        
        switch response.event {
        case .typingStart(let user):
            if !user.isCurrent && (typingUsers.isEmpty || !typingUsers.contains(user)) {
                typingUsers.append(user)
                return .updateFooter(true)
            }
        case .typingStop(let user):
            if !user.isCurrent, let index = typingUsers.firstIndex(of: user) {
                typingUsers.remove(at: index)
                return .updateFooter(true)
            }
        case .messageNew(let message, let user, _, _, _):
            var reloadRow: Int? = nil
            
            if let lastItem = items.last, case .message(let lastMessage) = lastItem, lastMessage.user == user {
                reloadRow = nextRow - 1
            }
            
            items.append(.message(message))
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
    
    private func parseEphemeralChanges(_ ephemeralType: EphemeralType) -> ChannelChanges {
        if let message = ephemeralType.message {
            if ephemeralType.updated {
                return .itemUpdated(items.count, message)
            }
            
            return .itemAdded(items.count, nil, true)
        }
        
        return items.count > 0 ? .itemRemoved(items.count - 1) : .none
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
        if pagination == .pageSize {
            next = .none
        }
        
        loadPagination.onNext(pagination)
    }
    
    private func parseQuery(_ query: Query) -> ChannelChanges {
        var items = next == .none ? [ChatItem]() : self.items
        let currentCount = items.count
        
        if let first = items.first, case .loading = first {
            items.remove(at: 0)
        }
        
        var yesterdayStatusAdded = false
        var todayStatusAdded = false
        var index = 0
        let isNextPage = next != .none
        
        query.messages.forEach { message in
            if !yesterdayStatusAdded, message.created.isYesterday {
                yesterdayStatusAdded = true
                items.insert(.status(ChannelPresenter.statusYesterdayTitle,
                                     "at \(DateFormatter.time.string(from: message.created))"), at: index)
                index += 1
            }
            
            if !todayStatusAdded, message.created.isToday {
                todayStatusAdded = true
                items.insert(.status(ChannelPresenter.statusTodayTitle,
                                     "at \(DateFormatter.time.string(from: message.created))"), at: index)
                index += 1
            }
            
            items.insert(.message(message), at: index)
            index += 1
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
            if case .status(let title, _) = item {
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
        guard let message = Message(text: text) else {
            return
        }
        
        let requestCompletion: Client.Completion<MessageResponse> = { [weak self] result in
            if let self = self, let response = try? result.get(), response.message.type == .ephemeral {
                self.ephemeralSubject.onNext((response.message, self.hasEphemeralMessage))
            }
        }
        
        Client.shared.request(endpoint: ChatEndpoint.sendMessage(message, channel), connectionId: "", requestCompletion)
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
        
        let completion: Client.Completion<MessageResponse> = { _ in }
        Client.shared.request(endpoint: endpoint, connectionId: "", completion)
        
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
