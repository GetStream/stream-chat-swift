//
//  ChannelsPresenter.swift
//  StreamChat
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
    public lazy var channelsFilter: Filter<Channel.CodingKeys> = .key(.type, .equal(to: channelType))
    public var channelsSorting: [Sorting<Channel.CodingKeys>] = [.init(.lastMessageDate)]
    public let showChannelStatuses: Bool
    public var channelMessageExtraDataCallback: ChannelMessageExtraDataCallback?
    
    private(set) lazy var changes = Driver.merge(requestChanges, webSocketChanges)
    
    private lazy var requestChanges: Driver<ViewChanges> = request(startPaginationWith: pageSize)
        .map { [weak self] in self?.channelsEndpoint(pagination: $0) }
        .unwrap()
        .flatMapLatest { Client.shared.rx.request(endpoint: $0) }
        .map { [weak self] in self?.parseChannels($0) ?? .none }
        .filter { $0 != .none }
        .asDriver(onErrorJustReturn: .none)
    
    private lazy var webSocketChanges: Driver<ViewChanges> = Client.shared.webSocket.response
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
            
            return .channelPresenter(channelPresenter)
        })
        
        if response.channels.count == next.limit {
            next = .channelsNextPageSize + .offset(next.offset + next.limit)
            items.append(.loading(false))
        } else {
            next = pageSize
        }
        
        self.items = items
        
        return isNextPage ? .reloaded(row, items) : .reloaded(0, items)
    }
    
    private func parseChanges(response: WebSocket.Response) -> ViewChanges {
        guard let channelId = response.channelId else {
            return .none
        }
        
        switch response.event {
        case .messageNew(_, _, _, let channel):
            if let index = items.firstIndex(whereChannelId: channelId),
                let channelPresenter = items.remove(at: index).channelPresenter {
                channelPresenter.parseChanges(response: response)
                items.insert(.channelPresenter(channelPresenter), at: 0)
                return .itemMoved(fromRow: index, toRow: 0, items)
            } else if let channel = channel {
                let channelPresenter = ChannelPresenter(channel: channel, parentMessage: nil, showStatuses: showChannelStatuses)
                items.insert(.channelPresenter(channelPresenter), at: 0)
                return .itemAdded(0, nil, false, items)
            }
        case .messageDeleted(let message):
            if let index = items.firstIndex(whereChannelId: channelId),
                let channelPresenter = items[index].channelPresenter {
                channelPresenter.parseChanges(response: response)
                return .itemUpdated([index], [message], items)
            }
        default:
            break
        }
        
        return .none
    }
}
