//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollOptionResponse: Sendable, Decodable {
    /// Duration of the request in milliseconds
    let duration: String
    let pollOption: PollOptionPayload

    init(duration: String, pollOption: PollOptionPayload) {
        self.duration = duration
        self.pollOption = pollOption
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case pollOption = "poll_option"
    }
}
