//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A unique identifier of a device.
public typealias DeviceId = String

extension Data {
    /// Generates a device id string from device token data.
    var deviceId: DeviceId { map { String(format: "%02x", $0) }.joined() }
}

extension Device: Identifiable {}

extension Device: Equatable {
    public static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
            && lhs.createdAt == rhs.createdAt
            && lhs.disabled == rhs.disabled
            && lhs.disabledReason == rhs.disabledReason
            && lhs.hardwareId == rhs.hardwareId
            && lhs.pushProvider == rhs.pushProvider
            && lhs.pushProviderName == rhs.pushProviderName
            && lhs.userId == rhs.userId
            && lhs.voip == rhs.voip
    }
}
