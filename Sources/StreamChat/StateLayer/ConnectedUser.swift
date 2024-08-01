//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object which represents the currently logged in user.
public final class ConnectedUser {
    private let authenticationRepository: AuthenticationRepository
    private let currentUserUpdater: CurrentUserUpdater
    private let stateBuilder: StateBuilder<ConnectedUserState>
    private let userUpdater: UserUpdater
    
    init(user: CurrentChatUser, client: ChatClient, environment: Environment = .init()) {
        authenticationRepository = client.authenticationRepository
        currentUserUpdater = environment.currentUserUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
        stateBuilder = StateBuilder {
            environment.stateBuilder(
                user,
                client.databaseContainer
            )
        }
        userUpdater = environment.userUpdaterBuilder(
            client.databaseContainer,
            client.apiClient
        )
    }
    
    // MARK: - Accessing the State
    
    /// An observable object representing the current state of the user.
    @MainActor public lazy var state: ConnectedUserState = stateBuilder.build()
    
    // MARK: - Connected User Data
    
    /// Updates the currently logged-in user's data.
    ///
    /// - Note: This does partial update and only updates existing data when a non-nil value is specified.
    ///
    /// - Parameters:
    ///   - name: The name to be set to the user.
    ///   - imageURL: The URL of the avatar image.
    ///   - privacySettings: The privacy settings of the user. Example: If the user does not want to expose typing events or read events.
    ///   - role: The role for the user.
    ///   - extraData: Additional data associated with the user.
    ///
    /// - Throws: An error while communicating with the Stream API or when user is not logged in.
    public func update(
        name: String? = nil,
        imageURL: URL? = nil,
        privacySettings: UserPrivacySettings? = nil,
        role: UserRole? = nil,
        extraData: [String: RawJSON] = [:]
    ) async throws {
        try await currentUserUpdater.updateUserData(
            currentUserId: try currentUserId(),
            name: name,
            imageURL: imageURL,
            privacySettings: privacySettings,
            role: role,
            userExtraData: extraData
        )
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
    /// - Note: Devices can be read later from ``ConnectedUserState/devices``.
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
    /// - Parameter device: The device information required for registering the device. Use ``PushDevice/apn(token:providerName:)`` for APN.
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
    
    // MARK: - Moderating Users
    
    /// Mutes the user in all the channels.
    ///
    /// - Note: Messages from muted users are not delivered via push notifications.
    ///
    /// - Parameter userId: The id of the user to mute.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func muteUser(_ userId: UserId) async throws {
        try await userUpdater.muteUser(userId)
    }
    
    /// Unmutes the user in all the channels.
    ///
    /// - Parameter userId: The id of the user to unmute.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func unmuteUser(_ userId: UserId) async throws {
        try await userUpdater.unmuteUser(userId)
    }
    
    /// Blocks the user in all the channels.
    ///
    /// - Parameter userId: The id of the user to mute.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func blockUser(_ userId: UserId) async throws {
        try await userUpdater.blockUser(userId)
    }
    
    /// Unblocks the user in all the channels.
    ///
    /// - Parameter userId: The id of the user to unmute.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func unblockUser(_ userId: UserId) async throws {
        try await userUpdater.unblockUser(userId)
    }
    
    /// Get all blocked users.
    ///
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    public func loadBlockedUsers() async throws -> [BlockedUserDetails] {
        try await currentUserUpdater.loadBlockedUsers()
    }
    
    /// Flags the specified user.
    ///
    /// - Parameter userId: The id of the user to flag.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func flag(_ userId: UserId) async throws {
        try await userUpdater.flag(userId)
    }
    
    /// Unflags the specified user.
    ///
    /// - Parameter userId: The id of the user to unflag.
    ///
    /// - Throws: An error while communicating with the Stream API.
    public func unflag(_ userId: UserId) async throws {
        try await userUpdater.unflag(userId)
    }
    
    // MARK: - Private
    
    private func currentUserId() throws -> UserId {
        guard let id = authenticationRepository.currentUserId else { throw ClientError.CurrentUserDoesNotExist() }
        return id
    }
}

extension ConnectedUser {
    struct Environment {
        var stateBuilder: @MainActor(
            _ user: CurrentChatUser,
            _ database: DatabaseContainer
        ) -> ConnectedUserState = { @MainActor in
            ConnectedUserState(user: $0, database: $1)
        }
        
        var currentUserUpdaterBuilder = CurrentUserUpdater.init
        
        var userUpdaterBuilder: (
            _ database: DatabaseContainer,
            _ apiClient: APIClient
        ) -> UserUpdater = UserUpdater.init
    }
}
