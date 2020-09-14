//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func webSocketConnect<UserData: UserExtraData>(
        userId: UserId,
        role: UserRole = .user,
        extraData: UserData? = nil
    ) -> Endpoint<EmptyResponse> {
        .init(
            path: "connect",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["json": WebSocketConnectPayload(userId: userId, userRole: role, extraData: extraData)]
        )
    }
}
