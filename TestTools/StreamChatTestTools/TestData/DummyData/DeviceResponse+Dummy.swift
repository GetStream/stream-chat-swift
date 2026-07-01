//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension DeviceResponse {
    static func dummy(pushProvider: String = "apn", userId: String = .unique) -> DeviceResponse {
        .init(
            createdAt: .unique,
            id: .unique,
            pushProvider: pushProvider,
            userId: userId
        )
    }
}

extension ListDevicesResponse {
    static func dummy(devices: [DeviceResponse] = [.dummy(), .dummy()]) -> ListDevicesResponse {
        .init(devices: devices, duration: "")
    }
}
