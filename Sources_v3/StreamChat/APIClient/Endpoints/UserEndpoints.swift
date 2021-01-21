//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func users<ExtraData: UserExtraData>(query: _UserListQuery<ExtraData>)
        -> Endpoint<UserListPayload<ExtraData>> {
        .init(
            path: "users",
            method: .get,
            queryItems: nil,
            requiresConnectionId: query.options.contains(oneOf: [.presence, .state, .watch]),
            body: ["payload": query]
        )
    }
    
    static func updateUser<ExtraData: UserExtraData>(
        id: UserId,
        payload: UserUpdateRequestBody<ExtraData>
    ) -> Endpoint<UserUpdateResponse<ExtraData>> {
        let users: [String: AnyEncodable] = [
            "id": AnyEncodable(id),
            "set": AnyEncodable(payload)
        ]
        let body: [String: AnyEncodable] = [
            "users": AnyEncodable([users])
        ]
        return Endpoint<UserUpdateResponse<ExtraData>>(
            path: "users",
            method: .patch,
            queryItems: nil,
            requiresConnectionId: false,
            body: body
        )
    }
}
