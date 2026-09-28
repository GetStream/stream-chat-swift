//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func webSocketConnect() -> Endpoint<EmptyResponse> {
        .init(
            path: .custom("/api/v2/connect"),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: nil
        )
    }
}
