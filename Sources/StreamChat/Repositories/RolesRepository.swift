//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Repository for searching roles.
///
/// Roles are transient and not persisted locally, so results are returned only
/// through the completion handler.
class RolesRepository: @unchecked Sendable {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func searchRoles(
        query: RoleSearchQuery,
        completion: @escaping @Sendable (Result<[Role], Error>) -> Void
    ) {
        apiClient.request(endpoint: .searchRoles(
            query: query.query,
            limit: query.limit,
            nameGt: query.nameGreaterThan,
            roleType: query.roleType?.rawValue,
            includeGlobalRoles: query.includeGlobalRoles
        )) { result in
            switch result {
            case .success(let response):
                completion(.success(response.roles.map { $0.asModel() }))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func searchRoles(query: RoleSearchQuery) async throws -> [Role] {
        try await withCheckedThrowingContinuation { continuation in
            searchRoles(query: query) { result in
                continuation.resume(with: result)
            }
        }
    }
}
