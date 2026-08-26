//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ListDevicesResponse: Sendable, Decodable {
    /// List of devices
    let devices: [Device]
    let duration: String

    init(devices: [Device], duration: String) {
        self.devices = devices
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case devices
        case duration
    }
}
