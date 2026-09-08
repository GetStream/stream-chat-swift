//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class MembersResponse: Sendable, Decodable {
    /// List of found members
    let members: [MemberPayload]

    init(members: [MemberPayload]) {
        self.members = members
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case members
    }
}
