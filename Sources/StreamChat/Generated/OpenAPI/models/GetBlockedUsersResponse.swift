//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetBlockedUsersResponse: Sendable, Decodable {
    /// Array of blocked user object
    let blocks: [BlockedUserResponse]

    init(blocks: [BlockedUserResponse]) {
        self.blocks = blocks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.blocks = try container.decodeArrayIgnoringFailures(
            [BlockedUserResponse].self,
            forKey: .blocks
        )
    }
}
