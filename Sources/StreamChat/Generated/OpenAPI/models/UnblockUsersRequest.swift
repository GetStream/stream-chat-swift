//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UnblockUsersRequest: Sendable, Codable, JSONEncodable {
    let blockedUserId: String

    init(blockedUserId: String) {
        self.blockedUserId = blockedUserId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedUserId = "blocked_user_id"
    }
}
