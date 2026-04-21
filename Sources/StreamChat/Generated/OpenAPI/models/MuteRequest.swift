//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MuteRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// User IDs to mute (if multiple users)
    var targetIds: [String]
    /// Duration of mute in minutes
    var timeout: Int?

    init(targetIds: [String], timeout: Int? = nil) {
        self.targetIds = targetIds
        self.timeout = timeout
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case targetIds = "target_ids"
        case timeout
    }

    static func == (lhs: MuteRequest, rhs: MuteRequest) -> Bool {
        lhs.targetIds == rhs.targetIds &&
            lhs.timeout == rhs.timeout
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(targetIds)
        hasher.combine(timeout)
    }
}
