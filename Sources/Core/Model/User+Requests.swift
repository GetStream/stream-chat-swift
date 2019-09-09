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
    
    /// Update or create a user.
    ///
    /// - Returns: an observable updated user.
    func update() -> Observable<User> {
        return Client.shared.update(user: self)
    }
    
    /// Mute the user.
    ///
    /// - Returns: an observable muted user.
    func mute() -> Observable<MutedUsersResponse> {
        guard !isCurrent else {
            return .empty()
        }
        
        return Client.shared.rx.connectedRequest(endpoint: .muteUser(self))
            .do(onNext: { Client.shared.user = $0.currentUser })
    }
    
    /// Unmute the user.
    ///
    /// - Returns: an observable unmuted user.
    func unmute() -> Observable<Void> {
        guard !isCurrent else {
            return .empty()
        }
        
        let request: Observable<EmptyData> = Client.shared.rx.request(endpoint: .unmuteUser(self))
        return Client.shared.connectedRequest(request.map { _ in Void() }
            // Remove unmuted user from the current user.
            .do(onNext: {
                if let currentUser = User.current {
                    var currentUser = currentUser
                    var mutedUsers = currentUser.mutedUsers
                    
                    if let index = mutedUsers.firstIndex(where: { $0.user.id == self.id }) {
                        mutedUsers.remove(at: index)
                        currentUser.mutedUsers = mutedUsers
                        Client.shared.user = currentUser
                    }
                }
            }))
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

/// A muted users response.
public struct MutedUsersResponse: Decodable {
    private enum CodingKeys: String, CodingKey {
        case mutedUser = "mute"
        case currentUser = "own_user"
    }
    
    /// A muted user.
    public let mutedUser: MutedUser
    /// The current user.
    public let currentUser: User
}

/// A muted user.
public struct MutedUser: Decodable {
    private enum CodingKeys: String, CodingKey {
        case user = "target"
        case created = "created_at"
        case updated = "updated_at"
    }
    
    /// A muted user.
    public let user: User
    /// A created date.
    public let created: Date
    /// A updated date.
    public let updated: Date
}

/// A response with a list of devices.
public struct DevicesResponse: Decodable {
    /// A list of devices.
    public let devices: [Device]
}
