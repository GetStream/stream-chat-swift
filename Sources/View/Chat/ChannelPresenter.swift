//
//  ChannelPresenter.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ChannelPresenter {
    public typealias Completion = (_ error: Error?) -> Void
    
    static let limitPagination: Pagination = .limit(50)
    
    public private(set) var channel: Channel
    var members: [User] = []
    var items: [ChatItem] = []
    private var next: Pagination = .none
    
    init(channel: Channel) {
        self.channel = channel
    }
}

// MARK: - Update Channel

extension ChannelPresenter {
    
    func loadNext(_ completion: @escaping Completion) {
        if next != .none {
            load(pagination: next, completion)
        }
    }
    
    func load(pagination: Pagination = ChannelPresenter.limitPagination, _ completion: @escaping Completion) {
        guard let user = Client.shared.user else {
            return
        }
        
        if pagination == ChannelPresenter.limitPagination {
            next = .none
        }
        
        channel.query(members: [user], pagination: pagination) { [weak self] in
            self?.parseQuery($0, completion)
        }
    }
    
    private func parseQuery(_ result: Result<Query, ClientError>, _ completion: @escaping Completion) {
        do {
            var items = next == .none ? [ChatItem]() : self.items
            let query = try result.get()
            
            if let first = items.first, case .loading = first {
                items.remove(at: 0)
            }
            
            var yesterdayStatusAdded = false
            var todayStatusAdded = false
            var index = 0
            
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
            
            if next != .none {
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
            
            DispatchQueue.main.async {
                self.channel = query.channel
                self.members = query.members
                self.items = items
                completion(nil)
            }
        } catch {
            print("⚠️", error)
            DispatchQueue.main.async { completion(error) }
        }
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
    public func send(text: String, completion: @escaping Completion) {
        guard let message = Message(text: text) else {
            return
        }
        
        channel.send(message) { result in
            DispatchQueue.main.async { completion(result.error) }
        }
    }
}
