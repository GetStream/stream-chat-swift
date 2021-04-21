//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A unique identifier of a device.
public typealias DeviceId = String

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
    
    /// Init a device for Push Notifications.
    ///
    /// - Parameters:
    ///   - id: The push notifications device identifier.
    ///   - created: The date when the device token was created.
    init(_ id: DeviceId, createdAt: Date? = .init()) {
        self.id = id
        self.createdAt = createdAt
    }
}

extension Data {
    /// Generates a device token string from the device token data.
    var deviceToken: String { map { String(format: "%02x", $0) }.joined() }
}
