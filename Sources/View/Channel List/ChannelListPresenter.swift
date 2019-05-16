//
//  ChannelListPresenter.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 14/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public final class ChannelListPresenter {
    
    public let channelType: ChannelType
    public let showChannelStatuses: Bool
    private(set) var channelPresenters: [ChannelPresenter] = []
    
    init(channelType: ChannelType, showChannelStatuses: Bool = true) {
        self.channelType = channelType
        self.showChannelStatuses = showChannelStatuses
    }
    
    private(set) lazy var request: Driver<ViewChanges> = Client.shared.webSocket.connection
        .connectionId()
        .map { [weak self] connectionId -> (ChannelsQuery, String)? in
            if let self = self, let user = Client.shared.user {
                return (ChannelsQuery(filter: .init(type: self.channelType),
                                      sort: [.lastMessage(isAscending: false)],
                                      user: user),
                        connectionId)
            }
            
            return nil
        }
        .unwrap()
        .flatMapLatest { Client.shared.rx.request(endpoint: ChatEndpoint.channels($0), connectionId: $1) }
        .map { [weak self] in self?.parseChannels($0) ?? .none }
        .asDriver(onErrorJustReturn: .none)
    
    private(set) lazy var changes: Driver<ViewChanges> = Client.shared.webSocket.response
        .map { [weak self] in self?.parseChanges(response: $0) ?? .none }
        .filter { $0 != .none }
        .asDriver(onErrorJustReturn: .none)

    private func parseChannels(_ response: ChannelListResponse) -> ViewChanges {
        channelPresenters = response.channels.map { ChannelPresenter(query: $0, showStatuses: showChannelStatuses) }
        return .reloaded(0, .top)
    }
}

// MARK: - Changes

extension ChannelListPresenter {
    private func parseChanges(response: WebSocket.Response) -> ViewChanges {
        switch response.event {
        case .messageNew:
            if let index = channelPresenterIndex(response: response) {
                let channelPresenter = channelPresenters.remove(at: index)
                channelPresenter.parseChanges(response: response)
                channelPresenters.insert(channelPresenter, at: 0)
                return .itemMoved(fromRow: index, toRow: 0)
            }
        case .messageDeleted(let message):
            if let index = channelPresenterIndex(response: response) {
                let channelPresenter = channelPresenters[index]
                channelPresenter.parseChanges(response: response)
                return .itemUpdated(index, message)
            }
        default:
            break
        }
        
        return .none
    }
    
    private func channelPresenterIndex(response: WebSocket.Response) -> Int? {
        return channelPresenters.firstIndex(where: { $0.channel.id == response.channelId })
    }
}

// MARK: - Supporting Structs

public struct ChannelListResponse: Decodable {
    let channels: [Query]
}
