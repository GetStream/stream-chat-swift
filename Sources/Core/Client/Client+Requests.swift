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
        return connectedRequest(request.map { $0.channels })
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
        return connectedRequest(request.map { $0.users })
    }
    
    /// Update or create a user.
    ///
    /// - Returns: an observable updated user.
    func update(users: [User]) -> Observable<[User]> {
        let request: Observable<UpdatedUsersResponse> = rx.request(endpoint: .updateUsers(users))
        return connectedRequest(request.map { $0.users.values.map { $0 } })
    }
    
    /// Update or create a user.
    ///
    /// - Parameter user: a user.
    /// - Returns: an observable updated user.
    func update(user: User) -> Observable<User> {
        return update(users: [user]).map({ $0.first }).unwrap()
    }
    
    /// Mute a user.
    ///
    /// - Parameter user: a user.
    /// - Returns: an observable muted user.
    func mute(user: User) -> Observable<MutedUsersResponse> {
        return user.mute()
    }
    
    /// Unmute a user.
    ///
    /// - Parameter user: a user.
    /// - Returns: an observable unmuted user.
    func unmute(user: User) -> Observable<Void> {
        return user.unmute()
    }
}
