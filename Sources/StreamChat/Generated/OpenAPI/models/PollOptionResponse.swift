//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollOptionResponse: Sendable, Codable, JSONEncodable {
    let pollOption: PollOptionResponseData

    init(pollOption: PollOptionResponseData) {
        self.pollOption = pollOption
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case pollOption = "poll_option"
    }
}
