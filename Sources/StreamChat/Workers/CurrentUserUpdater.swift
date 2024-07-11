//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData
import Foundation

/// Updates current user data to the backend and updates local storage.
class CurrentUserUpdater: Worker {
    /// Updates the current user data.
    ///
    /// By default all data is `nil`, and it won't be updated unless a value is provided.
    ///
    /// - Parameters:
    ///   - currentUserId: The current user identifier.
    ///   - name: Optionally provide a new name to be updated.
    ///   - imageURL: Optionally provide a new image to be updated.
    ///   - privacySettings: The privacy settings of the user. Example: If the user does not want to expose typing events or read events.
    ///   - userExtraData: Optionally provide new user extra data to be updated.
    ///   - completion: Called when user is successfuly updated, or with error.
    func updateUserData(
        currentUserId: UserId,
        name: String?,
        imageURL: URL?,
        privacySettings: UserPrivacySettings?,
        role: UserRole?,
        userExtraData: [String: RawJSON]?,
        completion: ((Error?) -> Void)? = nil
    ) {
        let params: [Any?] = [name, imageURL, userExtraData]
        guard !params.allSatisfy({ $0 == nil }) else {
            log.warning("Update user request not performed. All provided data was nil.")
            completion?(nil)
            return
        }

        let payload = UserUpdateRequestBody(
            name: name,
            imageURL: imageURL,
            privacySettings: privacySettings.map { UserPrivacySettingsPayload(settings: $0) },
            role: role,
            extraData: userExtraData
        )

        apiClient
            .request(endpoint: .updateUser(id: currentUserId, payload: payload)) { [weak self] in
                switch $0 {
                case let .success(response):
                    self?.database.write({ (session) in
                        try session.saveCurrentUser(payload: response.user)
                    }) { completion?($0) }
                case let .failure(error):
                    completion?(error)
                }
            }
    }

    /// Registers a device for push notifications to the current user.
    /// `setUser` must be called before calling this.
    /// - Parameters:
    ///   - deviceId: The device id.
    ///   - pushProvider: The push provider.
    ///   - providerName: Name of the push configuration in dashboard. If nil, default configuration will be used.
    ///   - currentUserId: The current user identifier.
    ///   - completion: Called when device is successfully registered, or with error.
    func addDevice(
        deviceId: DeviceId,
        pushProvider: PushProvider,
        providerName: String? = nil,
        currentUserId: UserId,
        completion: ((Error?) -> Void)? = nil
    ) {
        database.write({ session in
            try session.saveCurrentDevice(deviceId)
        }, completion: { databaseError in
            if let databaseError {
                completion?(databaseError)
                return
            }
            self.apiClient
                .request(
                    endpoint: .addDevice(
                        userId: currentUserId,
                        deviceId: deviceId,
                        pushProvider: pushProvider,
                        providerName: providerName
                    ),
                    completion: { result in
                        if let error = result.error {
                            log.debug("Device token \(deviceId) failed to be registered on Stream's backend.\n Reason: \(error.localizedDescription)")
                            completion?(error)
                            return
                        }
                        log.debug("Device token \(deviceId) was successfully registered on Stream's backend.")
                        completion?(nil)
                    }
                )
        })
    }

    /// Removes a registered device from the current user.
    /// `setUser` must be called before calling this.
    /// - Parameters:
    ///   - id: Device id to be removed. You can obtain registered devices via `currentUser.devices`.
    ///   - currentUserId: The current user identifier.
    ///   If `currentUser.devices` is not up-to-date, please make an `fetchDevices` call.
    ///   - completion: Called when device is successfully deregistered, or with error.
    func removeDevice(id: DeviceId, currentUserId: UserId, completion: ((Error?) -> Void)? = nil) {
        database.write({ session in
            session.deleteDevice(id: id)
        }, completion: { databaseError in
            if let databaseError {
                completion?(databaseError)
                return
            }
            self.apiClient
                .request(
                    endpoint: .removeDevice(
                        userId: currentUserId,
                        deviceId: id
                    ),
                    completion: { result in
                        completion?(result.error)
                    }
                )
        })
    }

    /// Updates the registered devices for the current user from backend.
    /// - Parameters:
    ///     - currentUserId: The current user identifier.
    ///     - completion: Called when request is successfully completed, or with error.
    func fetchDevices(currentUserId: UserId, completion: ((Result<[Device], Error>) -> Void)? = nil) {
        apiClient.request(endpoint: .devices(userId: currentUserId)) { [weak self] result in
            do {
                var devices = [Device]()
                let devicesPayload = try result.get()
                self?.database.write({ (session) in
                    // Since this call always return all device, we want' to clear the existing ones
                    // to remove the deleted devices.
                    devices = try session.saveCurrentUserDevices(
                        devicesPayload.devices,
                        clearExisting: true
                    )
                    .map { try $0.asModel() }
                }) { error in
                    if let error {
                        completion?(.failure(error))
                    } else {
                        completion?(.success(devices))
                    }
                }
            } catch {
                completion?(.failure(error))
            }
        }
    }

    /// Marks all channels for a user as read.
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    func markAllRead(completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .markAllRead()) {
            completion?($0.error)
        }
    }

    func loadAllUnreads(completion: @escaping ((Result<CurrentUserUnreads, Error>) -> Void)) {
        apiClient.request(endpoint: .unreads()) { result in
            switch result {
            case .success(let response):
                let unreads = response.asModel()
                completion(.success(unreads))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Get all blocked users.
    ///
    /// - Parameter completion: Called when the API call is finished. Called with `Error` if the remote update fails.
    ///
    func loadBlockedUsers(completion: @escaping (Result<[BlockedUserDetails], Error>) -> Void) {
        apiClient.request(endpoint: .loadBlockedUsers()) {
            switch $0 {
            case let .success(payload):
                self.database.write({ session in
                    session.currentUser?.blockedUserIds = Set(payload.blockedUsers.map(\.blockedUserId))
                }, completion: {
                    if let error = $0 {
                        log.error("Failed to save blocked users to the database. Error: \(error)")
                    }
                    let blockedUsers = payload.blockedUsers.map {
                        BlockedUserDetails(userId: $0.blockedUserId, blockedAt: $0.createdAt)
                    }
                    completion(.success(blockedUsers))
                })
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}

extension CurrentUserUpdater {
    func addDevice(_ device: PushDevice, currentUserId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            addDevice(
                deviceId: device.deviceId,
                pushProvider: device.pushProvider,
                providerName: device.providerName,
                currentUserId: currentUserId
            ) { error in
                continuation.resume(with: error)
            }
        }
    }

    func removeDevice(id: DeviceId, currentUserId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            removeDevice(id: id, currentUserId: currentUserId) { error in
                continuation.resume(with: error)
            }
        }
    }

    func fetchDevices(currentUserId: UserId) async throws -> [Device] {
        try await withCheckedThrowingContinuation { continuation in
            fetchDevices(currentUserId: currentUserId) { result in
                continuation.resume(with: result)
            }
        }
    }

    func markAllRead(currentUserId: UserId) async throws {
        try await withCheckedThrowingContinuation { continuation in
            markAllRead { error in
                continuation.resume(with: error)
            }
        }
    }

    func loadBlockedUsers() async throws -> [BlockedUserDetails] {
        try await withCheckedThrowingContinuation { continuation in
            loadBlockedUsers { result in
                continuation.resume(with: result)
            }
        }
    }

    func updateUserData(
        currentUserId: UserId,
        name: String?,
        imageURL: URL?,
        privacySettings: UserPrivacySettings?,
        role: UserRole?,
        userExtraData: [String: RawJSON]?
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            updateUserData(
                currentUserId: currentUserId,
                name: name,
                imageURL: imageURL,
                privacySettings: privacySettings,
                role: role,
                userExtraData: userExtraData
            ) { error in
                continuation.resume(with: error)
            }
        }
    }
}
