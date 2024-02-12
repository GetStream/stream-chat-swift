//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ConnectRequest: Codable, Hashable {
    public var userDetails: UserObject
    public var device: DeviceFields? = nil

    public init(userDetails: UserObject, device: DeviceFields? = nil) {
        self.userDetails = userDetails
        self.device = device
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case userDetails = "user_details"
        case device
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(userDetails, forKey: .userDetails)
        try container.encode(device, forKey: .device)
    }
}
