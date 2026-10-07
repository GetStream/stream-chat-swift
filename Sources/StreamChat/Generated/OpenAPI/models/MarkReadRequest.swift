//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MarkReadRequest: Sendable, Encodable, JSONEncodable {
    /// Optional Thread ID to specifically mark a given thread as read
    let threadId: String?

    init(threadId: String? = nil) {
        self.threadId = threadId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case threadId = "thread_id"
    }
}
