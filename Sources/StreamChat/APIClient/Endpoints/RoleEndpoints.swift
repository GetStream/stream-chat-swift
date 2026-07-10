//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Endpoint {
    static func searchRoles(query: RoleSearchQuery) -> Endpoint<SearchRolesResponse> {
        .searchRoles(
            query: query.query,
            limit: query.limit,
            nameGt: query.nameGreaterThan,
            roleType: query.roleType?.rawValue,
            includeGlobalRoles: query.includeGlobalRoles
        )
    }
}
