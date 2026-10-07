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

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(threadId, forKey: .threadId)
    }
}
