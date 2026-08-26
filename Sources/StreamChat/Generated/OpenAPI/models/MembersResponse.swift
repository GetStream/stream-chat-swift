//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MembersResponse: Sendable, Decodable {
    /// Duration of the request in milliseconds
    let duration: String
    /// List of found members
    let members: [MemberPayload]

    init(duration: String, members: [MemberPayload]) {
        self.duration = duration
        self.members = members
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case members
    }
}
