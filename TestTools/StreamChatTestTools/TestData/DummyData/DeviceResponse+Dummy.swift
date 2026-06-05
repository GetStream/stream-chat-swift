//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension DeviceResponse {
    static var dummy: DeviceResponse {
        .init(
            createdAt: .unique,
            id: .unique,
            pushProvider: "",
            userId: ""
        )
    }
}

extension ListDevicesResponse {
    static var dummy: ListDevicesResponse {
        .init(devices: [DeviceResponse.dummy, DeviceResponse.dummy], duration: "")
    }
}
