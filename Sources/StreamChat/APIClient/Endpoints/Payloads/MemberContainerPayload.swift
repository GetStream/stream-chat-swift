//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct MemberContainerPayload: Decodable {
    let member: MemberPayload?

    init(from decoder: Decoder) throws {
        member = try? .init(from: decoder)
    }

    init(member: MemberPayload?) {
        self.member = member
    }
}
