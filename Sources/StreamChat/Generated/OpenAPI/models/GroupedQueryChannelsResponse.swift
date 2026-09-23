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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case groups
    }
}
