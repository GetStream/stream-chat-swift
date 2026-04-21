//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryFutureChannelBansResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// List of found future channel bans
    var bans: [FutureChannelBanResponse]
    /// Duration of the request in milliseconds
    var duration: String

    init(bans: [FutureChannelBanResponse], duration: String) {
        self.bans = bans
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case bans
        case duration
    }

    static func == (lhs: QueryFutureChannelBansResponse, rhs: QueryFutureChannelBansResponse) -> Bool {
        lhs.bans == rhs.bans &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(bans)
        hasher.combine(duration)
    }
}
