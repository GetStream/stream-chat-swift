//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

/// Mock implementation of `RolesRepository`.
final class RolesRepository_Mock: RolesRepository, @unchecked Sendable {
    var searchRoles_query: RoleSearchQuery?
    var searchRoles_completion_result: Result<[Role], Error>?

    override init(apiClient: APIClient) {
        super.init(apiClient: apiClient)
    }

    init() {
        super.init(apiClient: APIClient_Spy())
    }

    override func searchRoles(
        query: RoleSearchQuery,
        completion: @escaping @Sendable (Result<[Role], Error>) -> Void
    ) {
        searchRoles_query = query
        if let result = searchRoles_completion_result {
            completion(result)
        }
    }
}
