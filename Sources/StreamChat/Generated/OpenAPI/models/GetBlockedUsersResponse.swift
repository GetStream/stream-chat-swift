//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

final class GetBlockedUsersResponse: Sendable, Decodable {
    /// Array of blocked user object
    let blocks: [BlockedUserResponse]
    /// Duration of the request in milliseconds
    let duration: String

    init(blocks: [BlockedUserResponse], duration: String) {
        self.blocks = blocks
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blocks
        case duration
    }
}
