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
    ///   - completion: a completion block with `[User]`.
    func users(query: UsersQuery, _ completion: @escaping ClientCompletion<[User]>) {
        return rx.users(query: query).bindOnce(to: completion)
    }
    
    // MARK: Update User
    
    /// Update or create a user.
    /// - Parameter completion: a completion block with `[User]`.
    func update(users: [User], _ completion: @escaping ClientCompletion<[User]>) {
        return rx.update(users: users).bindOnce(to: completion)
    }
    
    /// Update or create a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `User`.
    func update(user: User, _ completion: @escaping ClientCompletion<User>) {
        return rx.update(user: user).bindOnce(to: completion)
    }
    
    // MARK: Mute User
    
    /// Mute a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `MutedUsersResponse`.
    func mute(user: User, _ completion: @escaping ClientCompletion<MutedUsersResponse>) {
        return user.mute().bindOnce(to: completion)
    }
    
    /// Unmute a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: an empty completion block.
    func unmute(user: User, _ completion: @escaping ClientCompletion<Void>) {
        return user.unmute().bindOnce(to: completion)
    }
    
    // MARK: Flag User
    
    /// Flag a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `FlagUserResponse`.
    func flag(user: User, _ completion: @escaping ClientCompletion<FlagUserResponse>) {
        return user.flag().bindOnce(to: completion)
    }
    
    /// Unflag a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `FlagUserResponse`.
    func unflag(user: User, _ completion: @escaping ClientCompletion<FlagUserResponse>) {
        return user.unflag().bindOnce(to: completion)
    }
}
