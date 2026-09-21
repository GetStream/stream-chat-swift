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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case bans
    }
}
