//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpsertConfigResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var config: ConfigResponse?
    var duration: String

    init(config: ConfigResponse? = nil, duration: String) {
        self.config = config
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case config
        case duration
    }

    static func == (lhs: UpsertConfigResponse, rhs: UpsertConfigResponse) -> Bool {
        lhs.config == rhs.config &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(config)
        hasher.combine(duration)
    }
}
