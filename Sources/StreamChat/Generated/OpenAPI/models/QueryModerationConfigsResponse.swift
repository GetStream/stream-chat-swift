//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class QueryModerationConfigsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// List of moderation configurations
    var configs: [ConfigResponse]
    var duration: String
    var next: String?
    var prev: String?

    init(configs: [ConfigResponse], duration: String, next: String? = nil, prev: String? = nil) {
        self.configs = configs
        self.duration = duration
        self.next = next
        self.prev = prev
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case configs
        case duration
        case next
        case prev
    }

    static func == (lhs: QueryModerationConfigsResponse, rhs: QueryModerationConfigsResponse) -> Bool {
        lhs.configs == rhs.configs &&
            lhs.duration == rhs.duration &&
            lhs.next == rhs.next &&
            lhs.prev == rhs.prev
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(configs)
        hasher.combine(duration)
        hasher.combine(next)
        hasher.combine(prev)
    }
}
