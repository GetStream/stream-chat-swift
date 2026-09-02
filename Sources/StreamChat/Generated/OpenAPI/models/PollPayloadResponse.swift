//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollPayloadResponse: Sendable, Decodable {
    let poll: PollPayload

    init(poll: PollPayload) {
        self.poll = poll
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case poll
    }
}
