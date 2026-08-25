//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryBannedUsersResponse: Sendable, Codable, JSONEncodable {
    /// List of found bans
    let bans: [BanResponse]
    /// Duration of the request in milliseconds
    let duration: String

    init(
        bans: [BanResponse],
        duration: String
    ) {
        self.bans = bans
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case bans
        case duration
    }
}
