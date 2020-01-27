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
    @discardableResult
    func queryUsers(_ query: UsersQuery, _ completion: @escaping Client.Completion<[User]>) -> URLSessionTask {
        return request(endpoint: .users(query)) { (result: Result<UsersResponse, ClientError>) in
            completion(result.map({ $0.users }))
        }
    }
    
    // MARK: Update User
    
    /// Update or create a user.
    /// - Parameter completion: a completion block with `[User]`.
    @discardableResult
    func update(users: [User], _ completion: @escaping Client.Completion<[User]>) -> URLSessionTask {
        return request(endpoint: .updateUsers(users)) { (result: Result<UpdatedUsersResponse, ClientError>) in
            completion(result.map({ $0.users.compactMap({ $0.value }) }))
        }
    }
    
    /// Update or create a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `User`.
    @discardableResult
    func update(user: User, _ completion: @escaping Client.Completion<User>) -> URLSessionTask {
        return update(users: [user]) { (result: Result<[User], ClientError>) in
            completion(result.first(orError: .emptyUser))
        }
    }
    
    // MARK: Mute User
    
    /// Mute a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `MutedUsersResponse`.
    @discardableResult
    func mute(user: User, _ completion: @escaping Client.Completion<MutedUsersResponse>) -> URLSessionTask {
        if user.isCurrent {
            return .empty
        }
        
        let completion = doBefore(completion) { [unowned self] in self.user = $0.currentUser }
        return request(endpoint: .muteUser(user), completion)
    }
    
    /// Unmute a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: an empty completion block.
    @discardableResult
    func unmute(user: User, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> URLSessionTask {
        if user.isCurrent {
            return .empty
        }
        
        let completion = doBefore(completion) { [unowned self] _ in
            var currentUser = self.user
            var mutedUsers = currentUser.mutedUsers
            
            if let index = mutedUsers.firstIndex(where: { $0.user.id == user.id }) {
                mutedUsers.remove(at: index)
                currentUser.mutedUsers = mutedUsers
                self.user = currentUser
            }
        }
        
        return request(endpoint: .unmuteUser(user), completion)
    }
    
    // MARK: Flag User
    
    /// Flag a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `FlagUserResponse`.
    @discardableResult
    func flag(user: User, _ completion: @escaping Client.Completion<FlagUserResponse>) -> URLSessionTask {
        return flagUnflag(user, endpoint: .flagUser(user), completion)
    }
    
    /// Unflag a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `FlagUserResponse`.
    @discardableResult
    func unflag(user: User, _ completion: @escaping Client.Completion<FlagUserResponse>) -> URLSessionTask {
        return flagUnflag(user, endpoint: .unflagUser(user), completion)
    }
    
    private func flagUnflag(_ user: User,
                            endpoint: Endpoint,
                            _ completion: @escaping Client.Completion<FlagUserResponse>) -> URLSessionTask {
        return request(endpoint: endpoint) { (result: Result<FlagUserResponse, ClientError>) in
            let result = result.catchError { error in
                if case .responseError(let clientResponseError) = error,
                    clientResponseError.message.contains("flag already exists") {
                    return .success(.init(user: user, created: Date(), updated: Date()))
                }
                
                return .failure(error)
            }
            
            completion(result)
        }
    }
}
