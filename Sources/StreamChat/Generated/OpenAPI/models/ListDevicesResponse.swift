//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ListDevicesResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// List of devices
    var devices: [DeviceResponse]
    var duration: String

    init(devices: [DeviceResponse], duration: String) {
        self.devices = devices
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case devices
        case duration
    }

    static func == (lhs: ListDevicesResponse, rhs: ListDevicesResponse) -> Bool {
        lhs.devices == rhs.devices &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(devices)
        hasher.combine(duration)
    }
}
