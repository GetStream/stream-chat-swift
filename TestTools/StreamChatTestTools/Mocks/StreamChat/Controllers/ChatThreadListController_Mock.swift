//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public class ChatThreadListController_Mock: ChatThreadListController {
    public static func mock(query: ThreadListQuery, client: ChatClient? = nil) -> ChatThreadListController_Mock {
        .init(query: query, client: client ?? .mock())
    }

    public var threads_mock: [ChatThread]?
    public override var threads: LazyCachedMapCollection<ChatThread> {
        threads_mock.map { $0.lazyCachedMap { $0 } } ?? super.threads
    }

    public var state_mock: State?
    override public var state: DataController.State {
        get { state_mock ?? super.state }
        set { super.state = newValue }
    }

    public var synchronize_completion: (((any Error)?) -> Void)?
    public var synchronize_callCount = 0
    public override func synchronize(_ completion: (((any Error)?) -> Void)? = nil) {
        synchronize_callCount += 1
        synchronize_completion = completion
    }
}
