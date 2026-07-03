//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetBlockedUsersResponse: Sendable, Codable, JSONEncodable {
    /// Array of blocked user object
    let blocks: [BlockedUserResponse]

    init(blocks: [BlockedUserResponse]) {
        self.blocks = blocks
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blocks
    }
}
