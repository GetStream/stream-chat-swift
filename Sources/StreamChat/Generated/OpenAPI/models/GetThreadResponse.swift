//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetThreadResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: String
    var thread: ThreadStateResponse

    init(duration: String, thread: ThreadStateResponse) {
        self.duration = duration
        self.thread = thread
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case thread
    }

    static func == (lhs: GetThreadResponse, rhs: GetThreadResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.thread == rhs.thread
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(thread)
    }
}
