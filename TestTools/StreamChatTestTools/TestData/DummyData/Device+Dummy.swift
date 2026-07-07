//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension Device {
    static func dummy(pushProvider: String = "apn", userId: String = .unique) -> Device {
        .init(
            createdAt: .unique,
            id: .unique,
            pushProvider: pushProvider,
            userId: userId
        )
    }
}

extension ListDevicesResponse {
    static func dummy(devices: [Device] = [.dummy(), .dummy()]) -> ListDevicesResponse {
        .init(devices: devices, duration: "")
    }
}
