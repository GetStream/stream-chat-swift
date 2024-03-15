//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func webSocketConnect(
        userInfo: UserInfo
    ) -> Endpoint<EmptyResponse> {
        .init(
            path: .connect,
            method: .get,
            queryItems: ["stream-auth-type": "jwt"],
            requiresConnectionId: false,
            body: nil
        )
    }
}
