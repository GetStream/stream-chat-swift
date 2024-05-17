//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class ThreadListUpdater_Mock: ThreadListUpdater {
    init() {
        super.init(
            database: DatabaseContainer_Spy(),
            apiClient: APIClient_Spy()
        )
    }

    static func mock() -> Self {
        Self()
    }

    var loadThreadsCallCount = 0
    var loadThreadsCalledWith: ThreadListQuery?
    var loadThreadsCompletion: ((Result<ThreadListResponse, any Error>) -> Void)?

    override func loadThreads(
        query: ThreadListQuery,
        completion: @escaping (Result<ThreadListResponse, any Error>) -> Void
    ) {
        loadThreadsCallCount += 1
        loadThreadsCalledWith = query
        loadThreadsCompletion = completion
    }
}
