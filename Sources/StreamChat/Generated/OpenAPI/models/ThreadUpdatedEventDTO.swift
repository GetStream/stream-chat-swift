//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ThreadUpdatedEventDTO: Sendable, Event, Decodable {
    let createdAt: Date
    let thread: ThreadResponse?
    let type: String

    init(createdAt: Date, thread: ThreadResponse? = nil, type: String = "thread.updated") {
        self.createdAt = createdAt
        self.thread = thread
        self.type = type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.thread = try container.decodeIfPresent(ThreadResponse.self, forKey: .thread)
        self.type = try container.decode(String.self, forKey: .type)
    }
}
