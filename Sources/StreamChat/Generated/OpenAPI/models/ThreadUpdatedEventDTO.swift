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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case createdAt = "created_at"
        case thread
        case type
    }
}
