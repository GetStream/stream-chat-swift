//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The information required to register a device for push notifications.
public struct PushDevice {
    public let deviceId: DeviceId
    public let provider: PushProvider

    private init(deviceId: DeviceId, provider: PushProvider) {
        self.deviceId = deviceId
        self.provider = provider
    }

    /// Creates a Push Device for APN Push Notifications.
    /// - Parameter token: The device token obtained via `didRegisterForRemoteNotificationsWithDeviceToken` function in `AppDelegate`.
    /// - Returns: The Push Device details.
    public static func apn(token: Data) -> Self {
        .init(deviceId: token.deviceId, provider: .apn)
    }

    /// Creates a Push Device for Firebase Push Notifications.
    /// - Parameter token: The FCM token.
    /// - Returns: The Push Device details.
    public static func firebase(token: String) -> Self {
        .init(deviceId: DeviceId(token), provider: .firebase)
    }
}
