//
//  Device.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 06/09/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A device for Push Notifications.
public struct Device: Codable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case id
        case created = "created_at"
    }
    /// A device identifier.
    public let id: String
    /// A created date.
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
