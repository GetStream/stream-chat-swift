//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    var poll: PollResponseData

    init(duration: String, poll: PollResponseData) {
        self.duration = duration
        self.poll = poll
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case poll
    }

    static func == (lhs: PollResponse, rhs: PollResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.poll == rhs.poll
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(poll)
    }
}
