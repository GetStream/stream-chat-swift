//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollOptionResponse: Sendable, Decodable {
    let pollOption: PollOptionPayload

    init(pollOption: PollOptionPayload) {
        self.pollOption = pollOption
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.pollOption = try container.decode(PollOptionPayload.self, forKey: .pollOption)
    }
}
