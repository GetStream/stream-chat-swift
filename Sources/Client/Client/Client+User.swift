//
//  Client+User.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 09/01/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: User Requests

public extension Client {
    
    /// Requests users with given parameters. Creates a `UsersQuery` and call the `queryUsers` with it.
    /// - Parameters:
    ///   - filter: a users filter.
    ///   - sort: a sorting.
    ///   - pagination: Pagination for query. Only supports `.limit` and `.offset`
    ///   - options: a query options.
    ///   - completion: a completion block with `[User]`.
    @discardableResult
    func queryUsers(filter: Filter,
                    sort: Sorting? = nil,
                    pagination: Pagination = [.usersPageSize],
                    options: QueryOptions = [],
                    _ completion: @escaping Client.Completion<[User]>) -> Cancellable {
        queryUsers(query: .init(filter: filter, sort: sort, pagination: pagination, options: options), completion)
    }
    
    /// Requests users with a given query (see `UsersQuery`).
    /// - Parameters:
    ///   - query: a users query (see `UsersQuery`).
    ///   - completion: a completion block with `[User]`.
    @discardableResult
    func queryUsers(query: UsersQuery, _ completion: @escaping Client.Completion<[User]>) -> Cancellable {
        request(endpoint: .users(query)) { (result: Result<UsersResponse, ClientError>) in
            completion(result.map(to: \.users))
        }
    }
    
    // MARK: Update User
    
    /// Update or create a user.
    /// - Parameter completion: a completion block with `[User]`.
    @discardableResult
    func update(users: [User], _ completion: @escaping Client.Completion<[User]>) -> Cancellable {
        request(endpoint: .updateUsers(users)) { [unowned self] (result: Result<UpdatedUsersResponse, ClientError>) in
            var updatedCompletion = completion
            let usersResult = result.map(to: \.users)
            
            if let currentUserUpdated = usersResult.value?[self.user.id] {
                updatedCompletion = doBefore(completion) { _ in self.userAtomic.set(currentUserUpdated) }
            }
            
            updatedCompletion(usersResult.compactMap(to: \.value))
        }
    }
    
    /// Update or create a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `User`.
    @discardableResult
    func update(user: User, _ completion: @escaping Client.Completion<User>) -> Cancellable {
        update(users: [user]) { (result: Result<[User], ClientError>) in
            completion(result.first(orError: .emptyUser))
        }
    }
    
    // MARK: Mute User
    
    /// Mute a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `MutedUsersResponse`.
    @discardableResult
    func mute(user: User, _ completion: @escaping Client.Completion<MutedUsersResponse>) -> Cancellable {
        if user.isCurrent {
            return Subscription.empty
        }
        
        let completion = doBefore(completion) { [unowned self] in self.userAtomic.set($0.currentUser) }
        return request(endpoint: .muteUser(user), completion)
    }
    
    /// Unmute a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: an empty completion block.
    @discardableResult
    func unmute(user: User, _ completion: @escaping Client.Completion<EmptyData> = { _ in }) -> Cancellable {
        if user.isCurrent {
            return Subscription.empty
        }
        
        let completion = doBefore(completion) { [unowned self] _ in
            self.userAtomic.update { oldUser in
                var currentUser = oldUser
                currentUser.mutedUsers = oldUser.mutedUsers.filter { $0.user.id != user.id }
                return currentUser
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
    func flag(user: User, _ completion: @escaping Client.Completion<FlagUserResponse>) -> Cancellable {
        let completion = doAfter(completion) { _ in
            User.flaggedUsers.insert(user)
        }
        
        return toggleFlag(user, endpoint: .flagUser(user), completion)
    }
    
    /// Unflag a user.
    /// - Parameters:
    ///   - user: a user.
    ///   - completion: a completion block with `FlagUserResponse`.
    @discardableResult
    func unflag(user: User, _ completion: @escaping Client.Completion<FlagUserResponse>) -> Cancellable {
        let completion = doAfter(completion) { _ in
            User.flaggedUsers.remove(user)
        }
        
        return toggleFlag(user, endpoint: .unflagUser(user), completion)
    }
    
    private func toggleFlag(_ user: User,
                            endpoint: Endpoint,
                            _ completion: @escaping Client.Completion<FlagUserResponse>) -> Cancellable {
        request(endpoint: endpoint) { (result: Result<FlagResponse<FlagUserResponse>, ClientError>) in
            let result = result.catchError { error in
                if case .responseError(let clientResponseError) = error,
                    clientResponseError.message.contains("flag already exists") {
                    let flagUserResponse = FlagUserResponse(user: user, created: Date(), updated: Date())
                    return .success(FlagResponse(flag: flagUserResponse))
                }
                
                return .failure(error)
            }
            
            completion(result.map(to: \.flag))
        }
    }
}
