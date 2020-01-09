//
//  Client+Users.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: Users Requests

public extension Client {
    
    /// Requests users with a given query.
    /// - Parameters:
    ///   - query: a users query (see `UsersQuery`).
    ///   - completion: a completion block (see `ClientCompletion`).
    /// - Returns: a subscription.
    func users(query: UsersQuery, _ completion: @escaping ClientCompletion<[User]>) -> Subscription {
        return rx.users(query: query).bind(to: completion)
    }
    
    // MARK: Update User
    
    /// Update or create a user.
    /// - Parameter completion: a completion block (see `ClientCompletion`).
    /// - Returns: a subscription.
    func update(users: [User], _ completion: @escaping ClientCompletion<[User]>) -> Subscription {
        return rx.update(users: users).bind(to: completion)
    }
    
    /// Update or create a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block (see `ClientCompletion`).
    /// - Returns: a subscription.
    func update(user: User, _ completion: @escaping ClientCompletion<User>) -> Subscription {
        return rx.update(user: user).bind(to: completion)
    }
    
    // MARK: Mute User
    
    /// Mute a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block (see `ClientCompletion`).
    /// - Returns: a subscription.
    func mute(user: User, _ completion: @escaping ClientCompletion<MutedUsersResponse>) -> Subscription {
        return user.mute().bind(to: completion)
    }
    
    /// Unmute a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block (see `ClientCompletion`).
    /// - Returns: a subscription.
    func unmute(user: User, _ completion: @escaping EmptyClientCompletion) -> Subscription {
        return user.unmute().bind(to: completion)
    }
    
    // MARK: Flag User
    
    /// Flag a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block (see `ClientCompletion`).
    /// - Returns: a subscription.
    func flag(user: User, _ completion: @escaping ClientCompletion<FlagUserResponse>) -> Subscription {
        return user.flag().bind(to: completion)
    }
    
    /// Unflag a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block (see `ClientCompletion`).
    /// - Returns: a subscription.
    func unflag(user: User, _ completion: @escaping ClientCompletion<FlagUserResponse>) -> Subscription {
        return user.unflag().bind(to: completion)
    }
}
