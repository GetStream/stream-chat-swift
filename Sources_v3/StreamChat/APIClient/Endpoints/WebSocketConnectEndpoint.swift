//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func webSocketConnect<UserData: UserExtraData>(
        userId: UserId,
        name: String?,
        imageURL: URL?,
        role: UserRole = .user,
        extraData: UserData? = nil
    ) -> Endpoint<EmptyResponse> {
        .init(
            path: "connect",
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["json": WebSocketConnectPayload(
                userId: userId,
                name: name,
                imageURL: imageURL,
                userRole: role,
                extraData: extraData
            )]
        )
    }
}
