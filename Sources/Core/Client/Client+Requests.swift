//
//  Client+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Channels Requests

public extension Client {
    
    /// Requests channels with a given query.
    ///
    /// - Parameter query: a channels query (see `ChannelsQuery`).
    /// - Returns: a list of a channel response (see `ChannelResponse`).
    func channels(query: ChannelsQuery) -> Observable<[ChannelResponse]> {
        let request: Observable<ChannelsResponse> = rx.request(endpoint: .channels(query))
        return request.map { $0.channels }
    }
    
    /// Create a channel.
    ///
    /// - Parameters:
    ///     - type: a channel type (see `ChannelType`).1
    ///     - id: a channel id.
    ///     - name: a channel name.
    ///     - imageURL: a channel image URL.
    ///     - memberIds: members of the channel. If empty, then the current user will be added.
    ///     - extraData: an extra data for the channel.
    /// - Returns: an observable channel query (see `ChannelQuery`).
    func create(type: ChannelType,
                id: String = "",
                name: String? = nil,
                imageURL: URL? = nil,
                memberIds: [String] = [],
                extraData: Codable? = nil) -> Observable<ChannelResponse> {
        guard let currentUser = User.current else {
            return .empty()
        }
        
        var memberIds = memberIds
        
        if !memberIds.contains(currentUser.id) {
            memberIds.append(currentUser.id)
        }
        
        let channel = Channel(type: type, id: id, name: name, imageURL: imageURL, memberIds: memberIds, extraData: extraData)
        
        return rx.request(endpoint: .createChannel(channel))
    }
}

// MARK: - Users Requests

public extension Client {
    
    /// Requests users with a given query.
    ///
    /// - Parameter query: a users query (see `UsersQuery`).
    /// - Returns: an observable list of users.
    func users(query: UsersQuery) -> Observable<[User]> {
        let request: Observable<UsersResponse> = rx.request(endpoint: .users(query))
        return request.map { $0.users }
    }
    
    /// Update or create a user.
    ///
    /// - Returns: an observable updated user.
    func update(users: [User]) -> Observable<[User]> {
        let request: Observable<UpdatedUsersResponse> = rx.request(endpoint: .updateUsers(users))
        return request.map { $0.users.values.map { $0 } }
    }
}
