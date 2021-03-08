//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

struct DevicePayload: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
    }
    
    /// Device identifier.
    let id: DeviceId
    /// Date the device was created for the user.
    let createdAt: Date?
    
    init(id: DeviceId, createdAt: Date? = .init()) {
        self.id = id
        self.createdAt = createdAt
    }
}

struct DeviceListPayload: Decodable {
    /// List of devices belonging to user.
    let devices: [DevicePayload]
}
