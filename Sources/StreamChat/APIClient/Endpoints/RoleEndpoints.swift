//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func searchRoles(query: RoleSearchQuery) -> Endpoint<RoleListPayload> {
        .init(
            path: .rolesSearch,
            method: .get,
            queryItems: query,
            requiresConnectionId: false,
            body: nil
        )
    }
}
