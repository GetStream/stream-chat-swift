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

public final class ChannelsPresenter: Presenter<ChatItem> {
    public typealias ChannelMessageExtraDataCallback = (_ channel: Channel) -> ChannelPresenter.MessageExtraDataCallback?
    
    public let channelType: ChannelType
    public lazy var channelsFilter: ChannelsQuery.Filter = .type(channelType)
    public var channelsSorting: [ChannelsQuery.Sorting] = [.lastMessage(isAscending: false)]
    public let showChannelStatuses: Bool
    public var channelMessageExtraDataCallback: ChannelMessageExtraDataCallback?
    
    private(set) lazy var channelsRequest: Driver<ViewChanges> = request(startPaginationWith: pageSize)
        .map { [weak self] in self?.channelsEndpoint(pagination: $0) }
        .unwrap()
        .flatMapLatest { Client.shared.rx.request(endpoint: $0) }
        .map { [weak self] in self?.parseChannels($0) ?? .none }
        .filter { $0 != .none }
        .asDriver(onErrorJustReturn: .none)
    
    private(set) lazy var changes: Driver<ViewChanges> = Client.shared.webSocket.response
        .map { [weak self] in self?.parseChanges(response: $0) ?? .none }
        .filter { $0 != .none }
        .asDriver(onErrorJustReturn: .none)
    
    init(channelType: ChannelType, showChannelStatuses: Bool = true) {
        self.channelType = channelType
        self.showChannelStatuses = showChannelStatuses
        super.init(pageSize: .channelsPageSize)
    }
}

// MARK: - Parsing

extension ChannelsPresenter {
    
    private func channelsEndpoint(pagination: Pagination) -> ChatEndpoint? {
        if let user = Client.shared.user {
            return ChatEndpoint.channels(ChannelsQuery(filter: channelsFilter,
                                                       sort: channelsSorting,
                                                       user: user,
                                                       pagination: pagination))
        }
        
        return nil
    }
    
    private func parseChannels(_ response: ChannelsResponse) -> ViewChanges {
        let isNextPage = next != pageSize
        var items = isNextPage ? self.items : [ChatItem]()
        
        if let last = items.last, case .loading = last {
            items.removeLast()
        }
        
        let row = items.count
        
        items.append(contentsOf: response.channels.map {
            let channelPresenter = ChannelPresenter(query: $0, showStatuses: showChannelStatuses)
            
            if let channelMessageExtraDataCallback = self.channelMessageExtraDataCallback {
                channelPresenter.messageExtraDataCallback = channelMessageExtraDataCallback($0.channel)
            }
            
            return .channel(channelPresenter)
        })
        
        if response.channels.count == next.limit {
            next = .channelsNextPageSize + .offset(next.offset + next.limit)
            items.append(.loading)
        } else {
            next = pageSize
        }
        
        self.items = items
        
        return isNextPage ? .reloaded(row, items) : .reloaded(0, items)
    }
    
    private func parseChanges(response: WebSocket.Response) -> ViewChanges {
        switch response.event {
        case .messageNew:
            if let index = channelPresenterIndex(response: response),
                case .channel(let channelPresenter) = items.remove(at: index) {
                channelPresenter.parseChanges(response: response)
                items.insert(.channel(channelPresenter), at: 0)
                return .itemMoved(fromRow: index, toRow: 0, items)
            }
        case .messageDeleted(let message):
            if let index = channelPresenterIndex(response: response),
                case .channel(let channelPresenter) = items[index] {
                channelPresenter.parseChanges(response: response)
                return .itemUpdated(index, message, items)
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
