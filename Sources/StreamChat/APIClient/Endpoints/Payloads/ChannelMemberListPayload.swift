//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the incoming JSON from `/members` endpoint.
struct ChannelMemberListPayload: Decodable {
    /// A list of channel members for the specific `ChannelMemberListQuery`.
    let members: [MemberPayload]
}
