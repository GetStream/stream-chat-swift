//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class GroupedQueryChannelsResponse: Sendable, Decodable {
    /// Predefined channel groups keyed by group name
    let groups: [String: GroupedChannelsBucket]

    init(groups: [String: GroupedChannelsBucket]) {
        self.groups = groups
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.groups = try container.decode([String: GroupedChannelsBucket].self, forKey: .groups)
    }
}
