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
    /// - Parameter id: a Push Notifications device identifier.
    public init(_ id: String) {
        self.id = id
        created = Date()
    }
}

extension Data {
    /// Generates a device token string from the device token data.
    var deviceToken: String { map { String(format: "%02x", $0) }.joined() }
}
