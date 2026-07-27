//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PollResponse: Sendable, Codable, JSONEncodable {
    let poll: PollResponseData

    init(poll: PollResponseData) {
        self.poll = poll
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case poll
    }
}
