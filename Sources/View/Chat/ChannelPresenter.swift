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
    case updated(_ row: Int, UITableView.ScrollPosition)
    case itemAdded(_ row: Int, _ reloadRow: Int?, _ forceToScroll: Bool)
    case updateFooter(_ isUsersTyping: Bool, _ startWatching: User?, _ stopWatching: User?)
}

public final class ChannelPresenter {
    public typealias Completion = (_ error: Error?) -> Void
    
    static let limitPagination: Pagination = .limit(50)
    
    public private(set) var channel: Channel
    var members: [Member] = []
    private var next: Pagination = .none
    private var disposeBag = DisposeBag()
    
    private(set) var items: [ChatItem] = []
    private(set) var typingUsers: [User] = []
    private let loadPagination = PublishSubject<Pagination>()

    private(set) lazy var loading: Driver<ChannelChanges> =
        Observable.combineLatest(Client.shared.webSocket.connection.connected(), loadPagination.asObserver())
            .flatMapLatest { [weak self] (connection, pagination) -> Observable<Query> in
                if let self = self,
                    let user = Client.shared.user,
                    case .connected(let connectionId, _) = connection {
                    let query = Query(channel: self.channel, members: [Member(user: user)], pagination: pagination)
                    return Client.shared.rx.request(endpoint: ChatEndpoint.query(query), connectionId: connectionId)
                }
                
                return .empty()
            }
            .map { [weak self] in self?.parseQuery($0) ?? .none }
            .asDriver(onErrorJustReturn: .none)

    private(set) lazy var changes: Driver<ChannelChanges> = Client.shared.webSocket.response
        .map { [weak self] in self?.parseChanges(response: $0) ?? .none }
        .filter { $0 != .none }
        .asDriver(onErrorJustReturn: .none)
    
    init(channel: Channel) {
        self.channel = channel
    }
}

// MARK: -

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

// MARK: - Changes

extension ChannelPresenter {
    private func parseChanges(response: WebSocket.Response) -> ChannelChanges {
        guard response.channelId == channel.id else {
            return .none
        }
        
        let nextRow = items.count
        
        switch response.event {
        case .userStartWatching(let user, _):
            return .updateFooter(false, user, nil)
            
        case .userStopWatching(let user, _):
            return .updateFooter(false, nil, user)
            
        case .typingStart(let user):
            if typingUsers.isEmpty || !typingUsers.contains(user) {
                typingUsers.append(user)
                return .updateFooter(true, nil, nil)
            }
        case .typingStop(let user):
            if let index = typingUsers.firstIndex(of: user) {
                typingUsers.remove(at: index)
                return .updateFooter(true, nil, nil)
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
        default:
            break
        }
        
        return .none
    }
}

// MARK: - Load messages

extension ChannelPresenter {
    
    func loadNext() {
        if next != .none {
            load(pagination: next)
        }
    }
    
    func load(pagination: Pagination = ChannelPresenter.limitPagination) {
        if pagination == ChannelPresenter.limitPagination {
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
        
        if case .limit(let limitValue) = ChannelPresenter.limitPagination,
            limitValue > 0,
            query.messages.count == limitValue,
            let first = query.messages.first {
            next = ChannelPresenter.limitPagination + .lessThan(first.id)
            items.insert(.loading, at: 0)
        } else {
            next = .none
        }
        
        channel = query.channel
        members = query.members
        self.items = items
        
        if items.count > 0 {
            if isNextPage {
                return .updated(max(items.count - currentCount, 0), .top)
            }
            
            return .updated((items.count - 1), .top)
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

extension ChannelPresenter {
    public static var statusYesterdayTitle = "Yesterday"
    public static var statusTodayTitle = "Today"
}

// MARK: - Send Message

extension ChannelPresenter {
    public func send(text: String) {
        guard let message = Message(text: text) else {
            return
        }
        
        channel.send(message)
    }
}
