//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ListDevicesResponse: Sendable, Codable, JSONEncodable {
    /// List of devices
    let devices: [DeviceResponse]

    init(devices: [DeviceResponse]) {
        self.devices = devices
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case devices
    }
}
