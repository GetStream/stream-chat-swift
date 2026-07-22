//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MembersResponse: Sendable, Codable, JSONEncodable {
    /// Duration of the request in milliseconds
    let duration: String
    /// List of found members
    let members: [ChannelMemberResponse]

    init(
        duration: String,
        members: [ChannelMemberResponse]
    ) {
        self.duration = duration
        self.members = members
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case members
    }
}
