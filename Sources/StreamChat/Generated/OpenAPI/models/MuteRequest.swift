//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MuteRequest: Sendable, Codable, JSONEncodable {
    /// User IDs to mute (if multiple users)
    let targetIds: [String]
    /// Duration of mute in minutes
    let timeout: Int?

    init(targetIds: [String], timeout: Int? = nil) {
        self.targetIds = targetIds
        self.timeout = timeout
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case targetIds = "target_ids"
        case timeout
    }
}
