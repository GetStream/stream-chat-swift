//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func users<ExtraData: UserExtraData>(query: UserListQuery<ExtraData>)
        -> Endpoint<UserListPayload<ExtraData>> {
        .init(
            path: "users",
            method: .get,
            queryItems: nil,
            requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
            body: ["payload": query]
        )
    }
}
