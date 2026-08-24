//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollPayloadResponse: Sendable, Decodable {
    /// Duration of the request in milliseconds
    let duration: String
    let poll: PollPayload

    init(
        duration: String,
        poll: PollPayload
    ) {
        self.duration = duration
        self.poll = poll
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case poll
    }
}
