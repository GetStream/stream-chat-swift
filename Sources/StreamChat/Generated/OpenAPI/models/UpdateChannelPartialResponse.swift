//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateChannelPartialResponse: Sendable, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// List of updated members
    let members: [MemberPayload]

    init(channel: ChannelDetailPayload? = nil, members: [MemberPayload]) {
        self.channel = channel
        self.members = members
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case members
    }
}
