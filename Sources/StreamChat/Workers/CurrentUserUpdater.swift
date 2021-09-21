//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    ///   - userExtraData: Optionally provide new user extra data to be updated.
    ///   - completion: Called when user is successfuly updated, or with error.
    func updateUserData(
        currentUserId: UserId,
        name: String? = nil,
        imageURL: URL? = nil,
        userExtraData: [String: RawJSON]? = nil,
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
            extraData: userExtraData
        )
        
        apiClient
            .request(endpoint: .updateUser(id: currentUserId, payload: payload)) { [weak self] in
                switch $0 {
                case let .success(response):
                    self?.database.write({ (session) in
                        let userDTO = try session.saveUser(payload: response.user)
                        session.currentUser?.user = userDTO
                    }) { completion?($0) }
                case let .failure(error):
                    completion?(error)
                }
            }
    }
    
    /// Registers a device to the current user.
    /// `setUser` must be called before calling this.
    /// - Parameters:
    ///   - token: Device token, obtained via `didRegisterForRemoteNotificationsWithDeviceToken` function in `AppDelegate`.
    ///   - currentUserId: The current user identifier.
    ///   - completion: Called when device is successfully registered, or with error.
    func addDevice(
        token: Data,
        currentUserId: UserId,
        completion: ((Error?) -> Void)? = nil
    ) {
        let deviceId = token.deviceToken
        
        func saveCurrentDevice(deviceId: String, completion: ((Error?) -> Void)?) {
            database.write({ (session) in
                try session.saveCurrentDevice(deviceId)
            }) { completion?($0) }
        }
        
        // We already have the device saved
        if let currentUserDTO = database.viewContext.currentUser,
           currentUserDTO.devices.first(where: { $0.id == deviceId }) != nil {
            saveCurrentDevice(deviceId: deviceId, completion: completion)
            return
        }
        apiClient
            .request(
                endpoint: .addDevice(
                    userId: currentUserId,
                    deviceId: deviceId
                ),
                completion: { result in
                    if let error = result.error {
                        completion?(error)
                        return
                    }
                    saveCurrentDevice(deviceId: deviceId, completion: completion)
                }
            )
    }
    
    /// Removes a registered device from the current user.
    /// `setUser` must be called before calling this.
    /// - Parameters:
    ///   - id: Device id to be removed. You can obtain registered devices via `currentUser.devices`.
    ///   - currentUserId: The current user identifier.
    ///   If `currentUser.devices` is not up-to-date, please make an `fetchDevices` call.
    ///   - completion: Called when device is successfully deregistered, or with error.
    func removeDevice(id: String, currentUserId: UserId, completion: ((Error?) -> Void)? = nil) {
        apiClient
            .request(
                endpoint: .removeDevice(
                    userId: currentUserId,
                    deviceId: id
                ),
                completion: { [weak self] result in
                    if let error = result.error {
                        completion?(error)
                        return
                    }
                    self?.database.write({ (session) in
                        session.deleteDevice(id: id)
                    }) { completion?($0) }
                }
            )
    }
    
    /// Updates the registered devices for the current user from backend.
    /// - Parameters:
    ///     - currentUserId: The current user identifier.
    ///     - completion: Called when request is successfully completed, or with error.
    func fetchDevices(currentUserId: UserId, completion: ((Error?) -> Void)? = nil) {
        apiClient.request(endpoint: .devices(userId: currentUserId)) { [weak self] result in
            do {
                let devicesPayload = try result.get()
                self?.database.write({ (session) in
                    // Since this call always return all device, we want' to clear the existing ones
                    // to remove the deleted devices.
                    try session.saveCurrentUserDevices(devicesPayload.devices, clearExisting: true)
                }) { completion?($0) }
            } catch {
                completion?(error)
            }
        }
    }
}
