//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

// Completes with `search_completion_result` when set. Otherwise keeps the completion in
// `search_completions` so a test can finish requests in any order.
final class UnifiedSearchRepository_Mock: UnifiedSearchRepository, @unchecked Sendable {
    @Atomic var search_queries: [UnifiedSearchQuery] = []
    @Atomic var search_cursors: [[UnifiedSearchEntity: String]] = []
    @Atomic var search_completion_result: Result<UnifiedSearchResults, Error>?
    @Atomic var search_completions: [@Sendable (Result<UnifiedSearchResults, Error>) -> Void] = []

    override init(apiClient: APIClient, modelsTransformer: StreamModelsTransformer?) {
        super.init(apiClient: apiClient, modelsTransformer: modelsTransformer)
    }

    init() {
        super.init(apiClient: APIClient_Spy(), modelsTransformer: nil)
    }

    override func search(
        query: UnifiedSearchQuery,
        cursors: [UnifiedSearchEntity: String] = [:],
        currentUserId: UserId?,
        completion: @escaping @Sendable (Result<UnifiedSearchResults, Error>) -> Void
    ) {
        _search_queries.mutate { $0.append(query) }
        _search_cursors.mutate { $0.append(cursors) }
        if let result = search_completion_result {
            completion(result)
        } else {
            _search_completions.mutate { $0.append(completion) }
        }
    }
}
