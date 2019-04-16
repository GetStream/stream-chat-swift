//
//  ChannelPresenter.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ChannelPresenter {
    static let loadingStatus = "Loading..."
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
    
    func load(pagination: Pagination = ChannelPresenter.limitPagination, _ completion: @escaping () -> Void) {
        guard let user = Client.shared.user else {
            return
        }
        
        channel.query(members: [user], pagination: pagination) { [weak self] in self?.parseQuery($0, completion) }
    }
    
    func loadNext(_ completion: @escaping () -> Void) {
        if next != .none {
            load(pagination: next, completion)
        }
    }
    
    private func parseQuery(_ result: Result<Query, ClientError>, _ completion: @escaping () -> Void) {
        do {
            let query = try result.get()
            channel = query.channel
            members = query.members
            
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
                    removeDuplicatedStatus(statusTitle: ChannelPresenter.statusYesterdayTitle)
                }
                
                if todayStatusAdded {
                    removeDuplicatedStatus(statusTitle: ChannelPresenter.statusTodayTitle)
                }
            }
            
            if query.messages.count >= 25, let first = query.messages.first {
                next = ChannelPresenter.limitPagination + .lessThan(first.id)
                items.insert(.loading, at: 0)
            } else {
                next = .none
            }
        } catch let clientError as ClientError {
            print(clientError)
        } catch {
            print(error)
        }
        
        completion()
    }
    
    private func removeDuplicatedStatus(statusTitle: String) {
        if let index = items.lastIndex(where: {
            if case .status(let title, _) = $0 {
                return title == statusTitle
            }
            return false
        }) {
            items.remove(at: index)
        }
    }
}

extension ChannelPresenter {
    public static var statusYesterdayTitle = "Yesterday"
    public static var statusTodayTitle = "Today"
}
