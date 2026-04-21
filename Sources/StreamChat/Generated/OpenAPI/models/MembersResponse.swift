//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MembersResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    /// Duration of the request in milliseconds
    var duration: String
    /// List of found members
    var members: [ChannelMemberResponse]

    init(duration: String, members: [ChannelMemberResponse]) {
        self.duration = duration
        self.members = members
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case members
    }

    static func == (lhs: MembersResponse, rhs: MembersResponse) -> Bool {
        lhs.duration == rhs.duration &&
            lhs.members == rhs.members
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(duration)
        hasher.combine(members)
    }
}
