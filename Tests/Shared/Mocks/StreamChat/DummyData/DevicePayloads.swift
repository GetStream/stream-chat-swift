//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension DevicePayload {
    static var dummy: DevicePayload {
        .init(id: .unique, createdAt: .unique)
    }
}

extension DeviceListPayload {
    static var dummy: DeviceListPayload {
        .init(devices: [DevicePayload.dummy, DevicePayload.dummy])
    }
}
