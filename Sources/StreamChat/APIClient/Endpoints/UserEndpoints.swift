//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        payload: UserUpdateRequestBody,
        unset: [String]
    ) -> Endpoint<CurrentUserUpdateResponse> {
        let body = UpdateUsersPartialRequest(
            users: [
                UpdateUserPartialRequest(
                    id: id,
                    set: payload.set,
                    unset: unset
                )
            ]
        )
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

    static func pushPreferences(
        _ preferences: [PushPreferenceRequestPayload]
    ) -> Endpoint<PushPreferencesPayloadResponse> {
        .init(
            path: .pushPreferences,
            method: .post,
            body: UpsertPushPreferencesRequest(preferences: preferences)
        )
    }
}
