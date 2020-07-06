//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// An object representing a device which can receive push notifications.
public struct Device: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case id
        case created = "created_at"
    }
    
    /// The device identifier.
    public let id: String
    /// The date when the device for created.
    public let created: Date
    
    /// Init a device for Push Notifications.
    ///
    /// - Parameters:
    ///   - id: The push notifications device identifier.
    ///   - created: The date when the device token was created.
    public init(_ id: String, created: Date = .init()) {
        self.id = id
        self.created = created
    }
}

extension Data {
    /// Generates a device token string from the device token data.
    var deviceToken: String { map { String(format: "%02x", $0) }.joined() }
}
