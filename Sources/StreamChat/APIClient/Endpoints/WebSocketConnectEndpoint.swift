//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func webSocketConnect<ExtraData: ExtraDataTypes>(
        userInfo: UserInfo<ExtraData>
    ) -> Endpoint<EmptyResponse> {
        .init(
            path: "connect",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "json": WebSocketConnectPayload<ExtraData>(userInfo: userInfo)
            ]
        )
    }
}
