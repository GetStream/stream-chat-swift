//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class BlockUsersRequest: Sendable, Encodable, JSONEncodable {
    /// User id to block
    let blockedUserId: String

    init(blockedUserId: String) {
        self.blockedUserId = blockedUserId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedUserId = "blocked_user_id"
    }
}
