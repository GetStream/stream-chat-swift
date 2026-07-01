//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension RolePayload {
    static func dummy(
        createdAt: Date = .unique,
        custom: Bool = false,
        name: String = .unique,
        scopes: [String] = [],
        updatedAt: Date = .unique
    ) -> RolePayload {
        .init(
            createdAt: createdAt,
            custom: custom,
            name: name,
            scopes: scopes,
            updatedAt: updatedAt
        )
    }
}

extension SearchRolesResponse {
    static func dummy(
        duration: String = "",
        roles: [RolePayload] = []
    ) -> SearchRolesResponse {
        .init(duration: duration, roles: roles)
    }
}
