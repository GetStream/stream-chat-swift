//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UnblockUsersResponse: Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
    let duration: String

    init(duration: String) {
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
    }
}

extension UnblockUsersResponse: Hashable {
    static func == (lhs: UnblockUsersResponse, rhs: UnblockUsersResponse) -> Bool {
        lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
