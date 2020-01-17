//
//  Client+RxUsers.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

public extension Reactive where Base == Client {
    
    // MARK: Users Requests
    
    /// Requests users with a given query.
    ///
    /// - Parameter query: a users query (see `UsersQuery`).
    /// - Returns: an observable list of users.
    func users(query: UsersQuery) -> Observable<[User]> {
        let usersRequest: Observable<UsersResponse> = request(endpoint: .users(query))
        return connectedRequest(usersRequest.map({ $0.users }))
    }
    
    // MARK: Update User
    
    /// Update or create a user.
    ///
    /// - Returns: an observable updated user.
    func update(users: [User]) -> Observable<[User]> {
        let updateRequest: Observable<UpdatedUsersResponse> = request(endpoint: .updateUsers(users))
        return connectedRequest(updateRequest.map({ $0.users.values.map { $0 } }))
    }
    
    /// Update or create a user.
    ///
    /// - Parameter user: a user.
    /// - Returns: an observable updated user.
    func update(user: User) -> Observable<User> {
        return update(users: [user]).compactMap({ $0.first })
    }
    
    // MARK: Mute User
    
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
    
    // MARK: Flag User
    
    /// Flag a user.
    /// - Parameter user: a user.
    func flag(user: User) -> Observable<FlagUserResponse> {
        return user.flag()
    }
    
    /// Unflag a user.
    /// - Parameter user: a user.
    func unflag(user: User) -> Observable<FlagUserResponse> {
        return user.unflag()
    }
}
