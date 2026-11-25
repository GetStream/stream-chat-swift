//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Search results are snapshots, so they are converted straight from the response and skip the database.
class UnifiedSearchRepository: @unchecked Sendable {
    private let apiClient: APIClient
    private let modelsTransformer: StreamModelsTransformer?

    init(apiClient: APIClient, modelsTransformer: StreamModelsTransformer?) {
        self.apiClient = apiClient
        self.modelsTransformer = modelsTransformer
    }

    func search(
        query: UnifiedSearchQuery,
        cursors: [UnifiedSearchEntity: String] = [:],
        currentUserId: UserId?,
        completion: @escaping @Sendable (Result<UnifiedSearchResults, Error>) -> Void
    ) {
        let endpoint: Endpoint<SearchAllResponse> = .searchAll(
            searchAllRequest: query.asRequest(cursors: cursors),
            requiresConnectionId: false
        )
        apiClient.request(endpoint: endpoint) { [modelsTransformer] result in
            completion(result.map {
                $0.asModel(query: query, currentUserId: currentUserId, modelsTransformer: modelsTransformer)
            })
        }
    }

    func search(
        query: UnifiedSearchQuery,
        cursors: [UnifiedSearchEntity: String] = [:],
        currentUserId: UserId?
    ) async throws -> UnifiedSearchResults {
        try await withCheckedThrowingContinuation { continuation in
            search(query: query, cursors: cursors, currentUserId: currentUserId) { result in
                continuation.resume(with: result)
            }
        }
    }
}
