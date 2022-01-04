//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func webSocketConnect(
        userInfo: UserInfo
    ) -> Endpoint<EmptyResponse> {
        .init(
            path: "connect",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "json": WebSocketConnectPayload(userInfo: userInfo)
            ]
        )
    }
}
