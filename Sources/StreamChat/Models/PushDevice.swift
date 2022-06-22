//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// The information required to register a device for push notifications.
public struct PushDevice {
    /// Device token used to register a device for push notifications
    public let deviceId: DeviceId

    /// Provider of the remote push notification service (eg. `APN`, `Firebase`)
    public let pushProvider: PushProvider

    /// Name of your push configuration in the Stream's dashboard.
    public let providerName: String?

    private init(
        deviceId: DeviceId,
        pushProvider: PushProvider,
        providerName: String? = nil
    ) {
        self.deviceId = deviceId
        self.pushProvider = pushProvider
        self.providerName = providerName
    }

    /// Creates a Push Device for APN Push Notifications.
    /// - Parameter token: The device token obtained via `didRegisterForRemoteNotificationsWithDeviceToken` function in `AppDelegate`.
    /// - Parameter providerName: Name of your push configuration in the Stream's dashboard.
    /// The instantiated `PushDevice` struct.
    public static func apn(token: Data, providerName: String? = nil) -> Self {
        .init(
            deviceId: token.deviceId,
            pushProvider: .apn,
            providerName: providerName
        )
    }

    /// Creates a Push Device for Firebase Push Notifications.
    /// - Parameter token: The FCM token.
    /// - Parameter providerName: Name of your push configuration in the Stream's dashboard.
    /// - Returns: The instantiated `PushDevice` struct.
    public static func firebase(token: String, providerName: String? = nil) -> Self {
        .init(
            deviceId: DeviceId(token),
            pushProvider: .firebase,
            providerName: providerName
        )
    }
}
