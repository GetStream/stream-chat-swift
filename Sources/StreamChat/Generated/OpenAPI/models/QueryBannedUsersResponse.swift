//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryBannedUsersResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// List of found bans
    var bans: [BanResponse]
    /// Duration of the request in milliseconds
    var duration: String

    init(bans: [BanResponse], duration: String) {
        self.bans = bans
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case bans
        case duration
    }

    static func == (lhs: QueryBannedUsersResponse, rhs: QueryBannedUsersResponse) -> Bool {
        lhs.bans == rhs.bans &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bans)
        hasher.combine(duration)
    }
}
