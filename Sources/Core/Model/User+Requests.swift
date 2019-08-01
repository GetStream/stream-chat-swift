//
//  User+Requests.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 01/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import RxSwift

// MARK: - Requests

public extension User {
    
    /// Requests users with a given query.
    ///
    /// - Parameter query: a users query (see `UsersQuery`).
    /// - Returns: an observable list of users.
    static func users(query: UsersQuery) -> Observable<[User]> {
        let request: Observable<UsersResponse> = Client.shared.rx.request(endpoint: .users(query))
        return request.map { $0.users }
    }
    
    /// Update or create a user.
    ///
    /// - Returns: an observable updated user.
    func update() -> Observable<User> {
        return User.update(users: [self]).map({ $0.first }).unwrap()
    }
    
    /// Update or create a user.
    ///
    /// - Returns: an observable updated user.
    static func update(users: [User]) -> Observable<[User]> {
        let request: Observable<UpdatedUsersResponse> = Client.shared.rx.request(endpoint: .updateUsers(users))
        return request.map { $0.users.values.map { $0 } }
    }
}

/// A response with a list of users.
public struct UsersResponse: Decodable {
    /// A list of users.
    public let users: [User]
}

/// A response with a list of users by id.
public struct UpdatedUsersResponse: Decodable {
    /// A list of users by Id.
    public let users: [String: User]
}
