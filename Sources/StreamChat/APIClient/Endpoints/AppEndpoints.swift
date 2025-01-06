//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func appSettings() -> Endpoint<AppSettingsPayload> {
        .init(
            path: .appSettings,
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
}
