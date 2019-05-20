//
//  ChannelsPresenter.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public final class ChannelsPresenter {
    
    public let channelType: ChannelType
    public let showChannelStatuses: Bool
    private let loadPagination = PublishSubject<Pagination>()
    private var next = Pagination.channelsPageSize
    private var items: [ChatItem] = []
    
    var itemsCount: Int {
        return items.count
    }
    
    init(channelType: ChannelType, showChannelStatuses: Bool = true) {
        self.channelType = channelType
        self.showChannelStatuses = showChannelStatuses
    }
    
    private(set) lazy var request: Driver<ViewChanges> =
        Observable.combineLatest(Client.shared.webSocket.connection, loadPagination.asObserver())
            .map { [weak self] in self?.parseConnection(connection: $0, pagination: $1) }
        .unwrap()
        .flatMapLatest { Client.shared.rx.request(endpoint: ChatEndpoint.channels($0), connectionId: $1) }
        .map { [weak self] in self?.parseChannels($0) ?? .none }
        .asDriver(onErrorJustReturn: .none)
    
    private(set) lazy var changes: Driver<ViewChanges> = Client.shared.webSocket.response
        .map { [weak self] in self?.parseChanges(response: $0) ?? .none }
        .filter { $0 != .none }
        .asDriver(onErrorJustReturn: .none)

    private func parseChannels(_ response: ChannelsResponse) -> ViewChanges {
        let isNextPage = next != .channelsPageSize
        var items = isNextPage ? self.items : [ChatItem]()
        
        if let last = items.last, case .loading = last {
            items.removeLast()
        }
        
        let row = items.count
        items.append(contentsOf: response.channels.map { .channel(ChannelPresenter(query: $0, showStatuses: showChannelStatuses)) })
        
        if items.count == next.limit {
            next = .channelsNextPageSize + .offset(next.offset + next.limit)
            items.append(.loading)
        } else {
            next = .channelsPageSize
        }
        
        self.items = items
        
        return isNextPage ? .reloaded(row, .bottom) : .reloaded(0, .top)
    }
    
    func item(at row: Int) -> ChatItem? {
        return row >= 0 && row < items.count ? items[row] : nil
    }
    
    func loadNext() {
        if next != .channelsPageSize {
            load(pagination: next)
        }
    }
    
    func load(pagination: Pagination = .channelsPageSize) {
        loadPagination.onNext(pagination)
    }
}

// MARK: - Connection

extension ChannelsPresenter {
    private func parseConnection(connection: WebSocket.Connection, pagination: Pagination) -> (ChannelsQuery, String)? {
        if case .connected(let connectionId, _) = connection, let user = Client.shared.user {
            let query = ChannelsQuery(filter: .init(type: self.channelType),
                                      sort: [.lastMessage(isAscending: false)],
                                      user: user,
                                      pagination: pagination)
            
            return (query, connectionId)
        }
        
        if !items.isEmpty {
            next = .channelsPageSize
            DispatchQueue.main.async { self.loadPagination.onNext(.channelsPageSize) }
        }
        
        return nil
    }
}

// MARK: - Changes

extension ChannelsPresenter {
    private func parseChanges(response: WebSocket.Response) -> ViewChanges {
        switch response.event {
        case .messageNew:
            if let index = channelPresenterIndex(response: response),
                case .channel(let channelPresenter) = items.remove(at: index) {
                channelPresenter.parseChanges(response: response)
                items.insert(.channel(channelPresenter), at: 0)
                return .itemMoved(fromRow: index, toRow: 0)
            }
        case .messageDeleted(let message):
            if let index = channelPresenterIndex(response: response),
                case .channel(let channelPresenter) = items[index] {
                channelPresenter.parseChanges(response: response)
                return .itemUpdated(index, message)
            }
        default:
            break
        }
        
        return .none
    }
    
    private func channelPresenterIndex(response: WebSocket.Response) -> Int? {
        return items.firstIndex {
            if case .channel(let channelPresenter) = $0 {
                return channelPresenter.channel.id == response.channelId
            }
            
            return false
        }
    }
}
