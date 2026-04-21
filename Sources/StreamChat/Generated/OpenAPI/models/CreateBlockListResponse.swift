//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class CreateBlockListResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var blocklist: BlockListResponse?
    /// Duration of the request in milliseconds
    var duration: String

    init(blocklist: BlockListResponse? = nil, duration: String) {
        self.blocklist = blocklist
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blocklist
        case duration
    }

    static func == (lhs: CreateBlockListResponse, rhs: CreateBlockListResponse) -> Bool {
        lhs.blocklist == rhs.blocklist &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(blocklist)
        hasher.combine(duration)
    }
}
