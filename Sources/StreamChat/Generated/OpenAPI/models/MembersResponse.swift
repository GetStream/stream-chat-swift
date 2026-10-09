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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.members = try container.decodeArrayIgnoringFailures(
            [MemberPayload].self,
            forKey: .members
        )
    }
}
