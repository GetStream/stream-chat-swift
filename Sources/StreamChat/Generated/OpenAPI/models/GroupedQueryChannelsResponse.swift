//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedQueryChannelsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    /// Predefined channel groups keyed by group name
    var groups: [String: GroupedChannelsBucket]

    init(duration: String, groups: [String: GroupedChannelsBucket]) {
        self.duration = duration
        self.groups = groups
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case groups
    }

    static func == (lhs: GroupedQueryChannelsResponse, rhs: GroupedQueryChannelsResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.groups == rhs.groups
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(groups)
    }
}
