//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ListBlockListResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var blocklists: [BlockListResponse]
    /// Duration of the request in milliseconds
    var duration: String

    init(blocklists: [BlockListResponse], duration: String) {
        self.blocklists = blocklists
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case blocklists
        case duration
    }

    static func == (lhs: ListBlockListResponse, rhs: ListBlockListResponse) -> Bool {
        lhs.blocklists == rhs.blocklists &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(blocklists)
        hasher.combine(duration)
    }
}
