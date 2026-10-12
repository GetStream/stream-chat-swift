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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.members = try container.decode([MemberPayload].self, forKey: .members)
    }
}
