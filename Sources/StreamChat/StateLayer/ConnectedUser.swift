//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents the currently logged in user.
@available(iOS 13.0, *)
public struct ConnectedUser {
    private let authenticationRepository: AuthenticationRepository
    private let currentUserUpdater: CurrentUserUpdater
    
    init(user: CurrentChatUser, client: ChatClient, environment: Environment = .init()) {
        authenticationRepository = client.authenticationRepository
        currentUserUpdater = environment.currentUserUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
        state = environment.stateBuilder(
            user,
            client.databaseContainer
        )
    }
    
    /// An observable object representing the current state of the user.
    public let state: ConnectedUserState
    
    /// Updates the currently logged-in user's data.
    ///
    /// - Note: Setting any arguments to nil will keep the existing value.
    ///
    /// - Parameters:
    ///   - name: The name to be set to the user.
    ///   - imageURL: The URL of the avatar image.
    ///   - extraData: Additional data associated with the user.
    ///
    /// - Throws: An error while communicating with the Stream API or when user is not logged in.
    public func update(name: String? = nil, imageURL: URL? = nil, extraData: [String: RawJSON] = [:]) async throws {
        try await currentUserUpdater.updateUserData(currentUserId: try currentUserId(), name: name, imageURL: imageURL, userExtraData: extraData)
    }
    
    // MARK: - Managing Channels
    
    /// Mark all the user's channels as read.
    ///
    /// - Throws: An error while communicating with the Stream API or when user is not logged in.
    public func markAllChannelsRead() async throws {
        try await currentUserUpdater.markAllRead(currentUserId: try currentUserId())
    }
    
    // MARK: - Managing User Devices
    
    /// Loads an array of devices associated with the logged-in user.
    ///
    /// - Note: Devices can be read later from ``ConnectedUserState.devices``.
    ///
    /// - Throws: An error while communicating with the Stream API or when user is not logged in.
    /// - Returns: An array of devices receiving push notifications.
    public func loadDevices() async throws -> [Device] {
        try await currentUserUpdater.fetchDevices(currentUserId: try currentUserId())
    }
    
    /// Registers the current user's device for push notifications.
    ///
    /// Registering a device associates it with the user and tells the push provider to send new message notifications to that device.
    ///
    /// - Tip: Register the user's device for remote push notifications once your user is successfully connected to Chat.
    ///
    /// - Parameter device: The device information required for registering the device. Use ``PushDevice.apn(token:providerName:)`` for APN.
    ///
    /// - Throws: An error while communicating with the Stream API or when user is not logged in.
    public func addDevice(_ device: PushDevice) async throws {
        try await currentUserUpdater.addDevice(device, currentUserId: try currentUserId())
    }
    
    /// Removes the specified device from the current user.
    ///
    /// Unregistering a device removes the device from the user and stops further new message notifications.
    ///
    /// - Parameter deviceId: The id of the device to unregister from push notifications.
    ///
    /// - Throws: An error while communicating with the Stream API or when user is not logged in.
    public func removeDevice(_ deviceId: DeviceId) async throws {
        try await currentUserUpdater.removeDevice(id: deviceId, currentUserId: try currentUserId())
    }
    
    // MARK: - Private
    
    private func currentUserId() throws -> UserId {
        guard let id = authenticationRepository.currentUserId else { throw ClientError.CurrentUserDoesNotExist() }
        return id
    }
}

@available(iOS 13.0, *)
extension ConnectedUser {
    struct Environment {
        var stateBuilder: (
            _ user: CurrentChatUser,
            _ database: DatabaseContainer
        ) -> ConnectedUserState = ConnectedUserState.init
        
        var currentUserUpdaterBuilder = CurrentUserUpdater.init
    }
}
