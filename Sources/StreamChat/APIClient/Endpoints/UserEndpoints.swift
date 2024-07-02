//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func users(query: UserListQuery)
        -> Endpoint<UserListPayload> {
        .init(
            path: .users,
            method: .get,
            queryItems: nil,
            requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
            body: ["payload": query]
        )
    }

    static func updateUser(
        id: UserId,
        payload: UserUpdateRequestBody
    ) -> Endpoint<CurrentUserUpdateResponse> {
        let users: [String: AnyEncodable] = [
            "id": AnyEncodable(id),
            "set": AnyEncodable(payload)
        ]
        let body: [String: AnyEncodable] = [
            "users": AnyEncodable([users])
        ]
        return Endpoint<CurrentUserUpdateResponse>(
            path: .users,
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }

    static func unreads() -> Endpoint<CurrentUserUnreadsPayload> {
        .init(
            path: .unread,
            method: .get,
            body: nil
        )
    }
}
