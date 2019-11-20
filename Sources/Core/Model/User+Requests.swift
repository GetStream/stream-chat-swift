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
    
    internal static var flaggedUsers = [User]()
    
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
        return Client.shared.connectedRequest(request.void()
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
    
    // MARK: Flag User
    
    /// Checks if the user is flagged (locally).
    var isFlagged: Bool {
        return User.flaggedUsers.contains(self)
    }
    
    /// Flag a user.
    func flag() -> Observable<FlagUserResponse> {
        guard !isCurrent else {
            return .empty()
        }
        
        return Client.shared.connectedRequest(flagUnflagUser(endpoint: .flagUser(self))
            .do(onNext: { _ in User.flaggedUsers.append(self) }))
    }
     
    /// Unflag a user.
    func unflag() -> Observable<FlagUserResponse> {
        guard !isCurrent else {
            return .empty()
        }
        
        return Client.shared.connectedRequest(flagUnflagUser(endpoint: .unflagUser(self))
            .do(onNext: { _ in
                if let index = User.flaggedUsers.firstIndex(where: { $0 == self }) {
                    User.flaggedUsers.remove(at: index)
                }
            }))
    }
    
    private func flagUnflagUser(endpoint: Endpoint) -> Observable<FlagUserResponse> {
        return Client.shared.flagUnflag(endpoint: endpoint,
                                        aleradyFlagged: FlagUserResponse(user: self, created: Date(), updated: Date()))
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

/// A response with a list of devices.
public struct DevicesResponse: Decodable {
    /// A list of devices.
    public let devices: [Device]
}

/// A request object to ban a user.
public struct UserBan: Encodable {
    private enum CodingKeys: String, CodingKey {
        case userId = "target_user_id"
        case channelType = "type"
        case channelId = "id"
        case timeoutInMinutes = "timeout"
        case reason
    }
    
    let userId: String
    let channelType: ChannelType
    let channelId: String
    let timeoutInMinutes: Int?
    let reason: String?
    
    init(user: User, channel: Channel, timeoutInMinutes: Int?, reason: String?) {
        userId = user.id
        channelType = channel.type
        channelId = channel.id
        self.timeoutInMinutes = timeoutInMinutes
        self.reason = reason
    }
}
