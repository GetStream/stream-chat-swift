//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData

struct ThreadListResponse {
    var threads: [ChatThread]
    var next: String?
}

class ThreadsRepository {
    let database: DatabaseContainer
    let apiClient: APIClient

    init(database: DatabaseContainer, apiClient: APIClient) {
        self.database = database
        self.apiClient = apiClient
    }

    func loadThreads(
        query: ThreadListQuery,
        completion: @escaping (Result<ThreadListResponse, Error>) -> Void
    ) {
        apiClient.request(endpoint: .threads(query: query)) { [weak self] result in
            switch result {
            case .success(let threadListPayload):
                var threads: [ChatThread] = []
                self?.database.write({ session in
                    if query.next == nil {
                        /// For now, there is no `ThreadListQuery.filter` support.
                        /// So we only have 1  thread list, which is all threads.
                        /// So when fetching the first page, we need to cleanup all threads.
                        try session.deleteAllThreads()
                    }
                    threads = try session.saveThreadList(payload: threadListPayload).map {
                        try $0.asModel()
                    }
                }, completion: { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(
                            ThreadListResponse(
                                threads: threads,
                                next: threadListPayload.next
                            )
                        ))
                    }
                })
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
