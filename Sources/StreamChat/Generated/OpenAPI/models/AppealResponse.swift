//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AppealResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Unique identifier of the created Appeal item
    var appealId: String
    var duration: String

    init(appealId: String, duration: String) {
        self.appealId = appealId
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case appealId = "appeal_id"
        case duration
    }

    static func == (lhs: AppealResponse, rhs: AppealResponse) -> Bool {
        lhs.appealId == rhs.appealId &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(appealId)
        hasher.combine(duration)
    }
}
