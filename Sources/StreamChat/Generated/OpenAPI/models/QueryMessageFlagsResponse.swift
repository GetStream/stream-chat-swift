//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryMessageFlagsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    /// The flags that match the query
    var flags: [MessageFlagResponse]

    init(duration: String, flags: [MessageFlagResponse]) {
        self.duration = duration
        self.flags = flags
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case flags
    }

    static func == (lhs: QueryMessageFlagsResponse, rhs: QueryMessageFlagsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.flags == rhs.flags
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(flags)
    }
}
