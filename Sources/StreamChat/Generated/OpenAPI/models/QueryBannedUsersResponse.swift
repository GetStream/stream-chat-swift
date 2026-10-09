//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryBannedUsersResponse: Sendable, Decodable {
    /// List of found bans
    let bans: [BanResponse]

    init(bans: [BanResponse]) {
        self.bans = bans
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.bans = try container.decodeArrayIgnoringFailures([BanResponse].self, forKey: .bans)
    }
}
