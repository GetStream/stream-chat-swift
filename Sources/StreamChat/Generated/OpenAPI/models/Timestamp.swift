//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class Timestamp: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var time: Date?

    init(time: Date? = nil) {
        self.time = time
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case time = "Time"
    }

    static func == (lhs: Timestamp, rhs: Timestamp) -> Bool {
        lhs.time == rhs.time
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(time)
    }
}
