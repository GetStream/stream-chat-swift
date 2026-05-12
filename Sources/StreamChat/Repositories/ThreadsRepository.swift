//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        completion: @escaping @Sendable (Result<ThreadListResponse, Error>) -> Void
    ) {
        let filter = query.filter?.toRawJSONDictionary() ?? [:]
        let request = QueryThreadsRequest(
            filter: filter.isEmpty ? nil : filter,
            limit: query.limit,
            memberLimit: nil,
            next: query.next,
            participantLimit: query.participantLimit,
            prev: nil,
            replyLimit: query.replyLimit,
            sort: query.sort.map { SortParamRequest(direction: $0.isAscending ? 1 : -1, field: $0.key.remoteKey) },
            watch: query.watch
        )
        apiClient.request(
            endpoint: Endpoint<QueryThreadsResponse>.queryThreads(queryThreadsRequest: request)
        ) { [weak self] result in
            switch result {
            case .success(let threadListPayload):
                nonisolated(unsafe) var threads: [ChatThread] = []
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
