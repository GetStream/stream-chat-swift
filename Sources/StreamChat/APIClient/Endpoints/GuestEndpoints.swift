//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    /// Builds the endpoint to obtain an access-token for a guest user.
    /// - Parameters:
    ///   - userId: The user's identifier
    ///   - extraData: The user's extra data
    /// - Returns: The endpoint that expects **GuestUserTokenPayload<ExtraData>** payload in a response
    static func guestUserToken(
        userId: UserId,
        name: String?,
        imageURL: URL?,
        extraData: [String: RawJSON]
    ) -> Endpoint<GuestUserTokenPayload> {
        .init(
            path: "guest",
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            requiresToken: false,
            body: ["user": GuestUserTokenRequestPayload(
                userId: userId,
                name: name,
                imageURL: imageURL,
                extraData: extraData
            )]
        )
    }
}
