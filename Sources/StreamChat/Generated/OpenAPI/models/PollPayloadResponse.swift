//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollPayloadResponse: Sendable, Decodable {
    let poll: PollPayload

    init(poll: PollPayload) {
        self.poll = poll
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.poll = try container.decode(PollPayload.self, forKey: .poll)
    }
}
