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
    
    /// A message search.
    /// - Parameters:
    ///   - filter: a filter for channels, e.g. .key("members", .in(["john"]))
    ///   - query: a search query.
    ///   - pagination: a pagination. It works via the standard limit and offset parameters.
    func search(filter: Filter = .none, query: String, pagination: Pagination = .channelsPageSize) -> Observable<[Message]> {
        guard !query.isBlank else {
            return .empty()
        }
        
        let query = SearchQuery(filter: filter, query: query, pagination: pagination)
        
        if case .none = query.filter {
            return .error(SearchQueryError.emptyFilter)
        }
        
        let request: Observable<SearchResponse> = rx.request(endpoint: .search(query))
        
        return connectedRequest(request.map { $0.messages.compactMap({ $0["message"] }) })
    }
    
    /// Requests channels with a given query.
    ///
    /// - Parameter query: a channels query (see `ChannelsQuery`).
    /// - Returns: a list of a channel response (see `ChannelResponse`).
    func channels(query: ChannelsQuery) -> Observable<[ChannelResponse]> {
        let request: Observable<ChannelsResponse> = rx.request(endpoint: .channels(query))
        return connectedRequest(request.map { $0.channels })
            .do(onNext: { [unowned self] in self.add(channelsToDatabase: $0, query: query) })
    }
    
    /// Requests channel with a given query.
    ///
    /// - Parameter query: a channels query (see `ChannelsQuery`).
    /// - Returns: a list of a channel response (see `ChannelResponse`).
    func channel(query: ChannelQuery) -> Observable<ChannelResponse> {
        return connectedRequest(.channel(query))
            .do(onNext: { channelResponse in
                if query.options.contains(.state) {
                    channelResponse.channel.add(messagesToDatabase: channelResponse.messages)
                }
            })
    }
    
    /// Get a message by id.
    /// - Parameter messageId: a message id.
    func message(with messageId: String) -> Observable<MessageResponse> {
        return connectedRequest(.message(messageId))
    }
    
    /// Mark all messages as readed.
    func markAllRead() -> Observable<Void> {
        let request: Observable<EmptyData> = rx.request(endpoint: .markAllRead)
        return connectedRequest(request.map({ _ in Void() }))
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
        return connectedRequest(request.map({ $0.users }))
    }
    
    // MARK: Update User
    
    /// Update or create a user.
    ///
    /// - Returns: an observable updated user.
    func update(users: [User]) -> Observable<[User]> {
        let request: Observable<UpdatedUsersResponse> = rx.request(endpoint: .updateUsers(users))
        return connectedRequest(request.map({ $0.users.values.map { $0 } }))
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
    
    func flagUnflag<T: Decodable>(endpoint: Endpoint, aleradyFlagged value: T) -> Observable<T> {
        let request: Observable<FlagResponse<T>> = rx.request(endpoint: endpoint)
        
        return request.map { $0.flag }
            .catchError { error -> Observable<T> in
                if let clientError = error as? ClientError,
                    case .responseError(let clientResponseError) = clientError,
                    clientResponseError.message.contains("flag already exists") {
                    return .just(value)
                }
                
                return .error(error)
        }
    }
}

// MARK: - Devices

public extension Client {
    
    /// Add a device for Push Notifications.
    ///
    /// - Parameter deviceToken: a device token.
    /// - Returns: an observable completion.
    func addDevice(deviceToken: Data) -> Observable<Void> {
        guard !deviceToken.isEmpty else {
            return .empty()
        }
        
        let deviceToken = deviceToken.map { String(format: "%02x", $0) }.joined()
        return addDevice(deviceId: deviceToken)
    }
    
    /// Add a device for Push Notifications.
    ///
    /// - Parameter deviceId: a Push Notifications device identifier.
    /// - Returns: an observable completion.
    func addDevice(deviceId: String) -> Observable<Void> {
        guard let user = user else {
            return .empty()
        }
        
        let device = Device(deviceId)
        
        guard !user.devices.contains(where: { $0.id == deviceId }) else {
            if user.currentDevice == nil {
                var user = user
                user.currentDevice = device
                self.user = user
            }
            
            return .empty()
        }
        
        return Client.shared.rx.connectedRequest(endpoint: .addDevice(deviceId: deviceId, user))
            .do(onNext: { [unowned self] _ in
                var user = user
                user.devices.append(device)
                user.currentDevice = device
                self.user = user
                self.logger?.log("📱 Device added with id: \(deviceId)")
            })
            .map { (_: EmptyData) in Void() }
    }
    
    /// Request a list if devices.
    ///
    /// - Returns: an observable list of devices.
    func requestDevices() -> Observable<DevicesResponse> {
        guard let user = User.current else {
            return .empty()
        }
        
        return Client.shared.rx.connectedRequest(endpoint: .devices(user))
            .do(onNext: { [unowned self] response in
                if let currentUser = User.current {
                    var user = currentUser
                    user.devices = response.devices
                    self.user = user
                    self.logger?.log("📱 Devices updated")
                }
            })
    }
    
    /// Remove a device.
    ///
    /// - Parameter deviceId: a Push Notifications device identifier.
    /// - Returns: an observable empty data.
    func removeDevice(deviceId: String) -> Observable<Void> {
        return Client.shared.connection.connected()
            .flatMapLatest { [unowned self] _ -> Observable<EmptyData> in
                if let user = User.current, user.devices.firstIndex(where: { $0.id == deviceId }) != nil {
                    return self.rx.connectedRequest(endpoint: .removeDevice(deviceId: deviceId, user))
                }
                
                self.logger?.log("📱 Device id not found")
                
                return .empty()
            }
            .void()
            .do(onNext: { [unowned self] in
                if let currentUser = User.current, let index = currentUser.devices.firstIndex(where: { $0.id == deviceId }) {
                    var user = currentUser
                    user.devices.remove(at: index)
                    self.user = user
                    self.logger?.log("📱 Device removed with id: \(deviceId)")
                }
            })
    }
}
