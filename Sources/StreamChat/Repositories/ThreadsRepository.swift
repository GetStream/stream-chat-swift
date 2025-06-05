//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreData

struct ThreadListResponse: Sendable {
    var threads: [ChatThread]
    var next: String?
}

class ThreadsRepository: @unchecked Sendable {
    let database: DatabaseContainer
    let apiClient: APIClient

    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }

    func loadThreads(
        query: ThreadListQuery,
        completion: @escaping @Sendable(Result<ThreadListResponse, Error>) -> Void
    ) {
        apiClient.request(endpoint: .threads(query: query)) { [weak self] result in
            switch result {
            case .success(let threadListPayload):
                self?.database.write(converting: { session in
                    if query.next == nil {
                        /// For now, there is no `ThreadListQuery.filter` support.
                        /// So we only have 1  thread list, which is all threads.
                        /// So when fetching the first page, we need to cleanup all threads.
                        try session.deleteAllThreads()
                    }
                    let threads = try session.saveThreadList(payload: threadListPayload).map {
                        try $0.asModel()
                    }
                    return ThreadListResponse(
                        threads: threads,
                        next: threadListPayload.next
                    )
                }, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
