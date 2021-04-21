//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type describes the incoming JSON from `/members` endpoint.
struct ChannelMemberListPayload<ExtraData: UserExtraData>: Decodable {
    /// A list of channel members for the specific `ChannelMemberListQuery`.
    let members: [MemberPayload<ExtraData>]
}
