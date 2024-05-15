//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import CoreData

/// Makes a thread list query call to the backend and updates the local storage with the results.
class ThreadListUpdater: Worker {
    /// The cursor to be used for fetching a new page of threads.
    var nextCursor: String?

    func loadThreads(
        query: ThreadListQuery,
        completion: @escaping (Result<[ChatThread], Error>) -> Void
    ) {
        apiClient.request(endpoint: .threads(query: query)) { [weak self] result in
            switch result {
            case .success(let threadListPayload):
                self?.nextCursor = threadListPayload.next
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
                    self?.nextCursor = threadListPayload.next
                }, completion: { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(threads))
                    }
                })
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
