//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension ChatClient {
    /// Creates a new `ThreadListController` with the provided thread query.
    /// - Returns: A new instance of `ChatThreadListController`.
    public func threadListController(query: ThreadListQuery) -> ChatThreadListController {
        .init(query: query, client: self)
    }
}
