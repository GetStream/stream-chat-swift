//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ListDevicesResponse: Sendable, Decodable {
    /// List of devices
    let devices: [Device]

    init(devices: [Device]) {
        self.devices = devices
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case devices
    }
}
