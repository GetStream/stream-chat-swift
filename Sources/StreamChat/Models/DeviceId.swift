//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A unique identifier of a device.
public typealias DeviceId = String

extension Data {
    /// Generates a device id string from device token data.
    var deviceId: DeviceId { map { String(format: "%02x", $0) }.joined() }
}
