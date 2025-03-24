//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

class ChatThreadListController_Mock: ChatThreadListController, @unchecked Sendable {
    static func mock(query: ThreadListQuery, client: ChatClient? = nil) -> ChatThreadListController_Mock {
        .init(query: query, client: client ?? .mock())
    }

    @Atomic var threads_mock: [ChatThread]?
    override var threads: LazyCachedMapCollection<ChatThread> {
        threads_mock.map { $0.lazyCachedMap { $0 } } ?? super.threads
    }

    @Atomic var state_mock: State?
    override var state: DataController.State {
        get { state_mock ?? super.state }
        set { super.state = newValue }
    }

    @Atomic var synchronize_completion: (((any Error)?) -> Void)?
    @Atomic var synchronize_callCount = 0
    override func synchronize(_ completion: (((any Error)?) -> Void)? = nil) {
        synchronize_callCount += 1
        synchronize_completion = completion
    }
}
