//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollOptionResponse: Sendable, Decodable {
    let pollOption: PollOptionPayload

    init(pollOption: PollOptionPayload) {
        self.pollOption = pollOption
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case pollOption = "poll_option"
    }
}
