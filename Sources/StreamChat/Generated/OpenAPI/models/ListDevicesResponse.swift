//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// List devices response
final class ListDevicesResponse: Sendable, Decodable {
    /// List of devices
    let devices: [Device]

    init(devices: [Device]) {
        self.devices = devices
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.devices = try container.decode([Device].self, forKey: .devices)
    }
}
