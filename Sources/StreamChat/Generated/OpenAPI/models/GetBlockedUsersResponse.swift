//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GetBlockedUsersResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Array of blocked user object
    var blocks: [BlockedUserResponse]
    /// Duration of the request in milliseconds
    var duration: String

    init(blocks: [BlockedUserResponse], duration: String) {
        self.blocks = blocks
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blocks
        case duration
    }

    static func == (lhs: GetBlockedUsersResponse, rhs: GetBlockedUsersResponse) -> Bool {
        lhs.blocks == rhs.blocks &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(blocks)
        hasher.combine(duration)
    }
}
