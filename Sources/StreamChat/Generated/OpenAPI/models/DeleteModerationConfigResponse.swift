//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeleteModerationConfigResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var duration: String

    init(duration: String) {
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
    }

    static func == (lhs: DeleteModerationConfigResponse, rhs: DeleteModerationConfigResponse) -> Bool {
        lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
    }
}
