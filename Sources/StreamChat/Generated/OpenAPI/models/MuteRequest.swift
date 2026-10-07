//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MuteRequest: Sendable, Encodable, JSONEncodable {
    /// User IDs to mute (if multiple users)
    let targetIds: [String]
    /// Duration of mute in minutes
    let timeout: Int?

    init(targetIds: [String], timeout: Int? = nil) {
        self.targetIds = targetIds
        self.timeout = timeout
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(targetIds, forKey: .targetIds)
        try container.encodeIfPresent(timeout, forKey: .timeout)
    }
}
