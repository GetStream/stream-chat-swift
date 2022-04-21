//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A unique identifier of a device.
public typealias DeviceId = String

extension Data {
    /// Generates a device id string from device token data.
    var deviceId: DeviceId { map { String(format: "%02x", $0) }.joined() }
}

/// An object representing a device which can receive push notifications.
public struct Device: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
    }

    /// The device identifier.
    public let id: DeviceId
    /// The date when the device for created.
    public let createdAt: Date?
}
