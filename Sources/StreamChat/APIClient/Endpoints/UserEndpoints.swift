//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func users(query: UserListQuery)
        -> Endpoint<UserListPayload> {
        .init(
            path: "users",
            method: .get,
            queryItems: nil,
            requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
            body: ["payload": query]
        )
    }
    
    static func updateUser(
        id: UserId,
        payload: UserUpdateRequestBody
    ) -> Endpoint<UserUpdateResponse> {
        let users: [String: AnyEncodable] = [
            "id": AnyEncodable(id),
            "set": AnyEncodable(payload)
        ]
        let body: [String: AnyEncodable] = [
            "users": AnyEncodable([users])
        ]
        return Endpoint<UserUpdateResponse>(
            path: "users",
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }
}
