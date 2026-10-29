//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class BlockUsersRequest: Sendable, Encodable, JSONEncodable {
    /// User id to block
    let blockedUserId: String

    init(blockedUserId: String) {
        self.blockedUserId = blockedUserId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encode(blockedUserId, forKey: .blockedUserId)
    }
}
