//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateThreadPartialResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var thread: ThreadResponse

    init(duration: String, thread: ThreadResponse) {
        self.duration = duration
        self.thread = thread
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case thread
    }

    static func == (lhs: UpdateThreadPartialResponse, rhs: UpdateThreadPartialResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.thread == rhs.thread
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(thread)
    }
}
