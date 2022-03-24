//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    /// Builds the endpoint to add a device to the user.
    /// The `userId` parameter must belong to the currently authorized user.
    /// - Parameters:
    ///   - userId: UserId for adding the device.
    ///   - deviceId: DeviceId to be added. DeviceId is obtained via
    ///   `didRegisterForRemoteNotificationsWithDeviceToken` function in `AppDelegate`.
    ///   - pushProvider: The push provider for this device.
    /// - Returns: The endpoint for adding a device.
    static func addDevice(
        userId: UserId,
        deviceId: DeviceId,
        pushProvider: PushProvider
    ) -> Endpoint<EmptyResponse> {
        .init(
            path: .devices,
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "user_id": userId,
                "id": deviceId,
                "push_provider": pushProvider.rawValue
            ]
        )
    }
    
    /// Builds the endpoint to remove a device from the user.
    /// The `userId` parameter must belong to the currently authorized user.
    /// - Parameters:
    ///   - userId: UserId for adding the device.
    ///   - deviceId: DeviceId to be added. DeviceId is obtained via
    ///   `didRegisterForRemoteNotificationsWithDeviceToken` function in `AppDelegate`.
    /// - Returns: The endpoint for removing a device.
    static func removeDevice(userId: UserId, deviceId: DeviceId) -> Endpoint<EmptyResponse> {
        .init(
            path: .devices,
            method: .delete,
            queryItems: ["user_id": userId, "id": deviceId],
            requiresConnectionId: false,
            body: nil
        )
    }
    
    /// Builds the endpoint to query devices registered to a user
    /// The `userId` parameter must belong to the currently authorized user.
    /// - Parameters:
    ///   - userId: UserId for adding the device.
    /// - Returns: The endpoint with `DevicesPayload` in the response.
    static func devices(userId: UserId) -> Endpoint<DeviceListPayload> {
        .init(
            path: .devices,
            method: .get,
            queryItems: ["user_id": userId],
            requiresConnectionId: false,
            body: nil
        )
    }
}
