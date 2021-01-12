//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func updateCurrentUser<ExtraData: UserExtraData>(
        payload: CurrentUserUpdateRequestBody<ExtraData>
    ) -> Endpoint<CurrentUserUpdateResponse<ExtraData>> {
        .init(
            path: "users",
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["users": [payload]]
        )
    }
}
