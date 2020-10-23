//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    /// Builds the endpoint to obtain an access-token for a guest user.
    /// - Parameters:
    ///   - userId: The user's identifier
    ///   - extraData: The user's extra data
    /// - Returns: The endpoint that expects **GuestUserTokenPayload<ExtraData>** payload in a response
    static func guestUserToken<ExtraData: UserExtraData>(
        userId: UserId,
        extraData: ExtraData
    ) -> Endpoint<GuestUserTokenPayload<ExtraData>> {
        .init(
            path: "guest",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["user": GuestUserTokenRequestPayload(userId: userId, extraData: extraData)]
        )
    }
}
