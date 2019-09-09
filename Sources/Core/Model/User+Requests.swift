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

// MARK: - Devices

public extension User {
    
    /// Add a device for Push Notifications.
    ///
    /// - Parameter deviceId: a Push Notifications device identifier.
    /// - Returns: an observable empty data.
    func addDevice(deviceId: String) -> Observable<EmptyData> {
        return Client.shared.rx.connectedRequest(endpoint: .addDevice(deviceId: deviceId, self))
            .do(onNext: { _ in
                var user = self
                user.devices.append(Device(deviceId))
                Client.shared.user = user
                Client.shared.logger?.log("📱", "Device added with id: \(deviceId)")
            })
    }
    
    /// Request a list if devices.
    ///
    /// - Returns: an observable list of devices.
    func requestDevices() -> Observable<DevicesResponse> {
        return Client.shared.rx.connectedRequest(endpoint: .devices(self))
            .do(onNext: { response in
                var user = self
                user.devices = response.devices
                Client.shared.user = user
                Client.shared.logger?.log("📱", "Devices updated")
            })
    }
    
    /// Remove a device.
    ///
    /// - Parameter deviceId: a Push Notifications device identifier.
    /// - Returns: an observable empty data.
    func removeDevice(deviceId: String) -> Observable<EmptyData> {
        return Client.shared.connection.connected()
            .flatMapLatest { _ -> Observable<EmptyData> in
                if self.devices.firstIndex(where: { $0.id == deviceId }) != nil {
                    return Client.shared.rx.connectedRequest(endpoint: .removeDevice(deviceId: deviceId, self))
                }
                
                Client.shared.logger?.log("📱", "Device id not found")
                
                return .empty()
            }
            .do(onNext: { _ in
                if let index = self.devices.firstIndex(where: { $0.id == deviceId }) {
                    var user = self
                    user.devices.remove(at: index)
                    Client.shared.user = user
                    Client.shared.logger?.log("📱", "Device removed with id: \(deviceId)")
                }
            })
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
