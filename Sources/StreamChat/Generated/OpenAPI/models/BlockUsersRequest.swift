//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BlockUsersRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// User id to block
    var blockedUserId: String

    init(blockedUserId: String) {
        self.blockedUserId = blockedUserId
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blockedUserId = "blocked_user_id"
    }

    static func == (lhs: BlockUsersRequest, rhs: BlockUsersRequest) -> Bool {
        lhs.blockedUserId == rhs.blockedUserId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(blockedUserId)
    }
}
