//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class UpdateChannelResponse: Sendable, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// List of channel members
    let members: [MemberPayload]
    /// Represents any chat message
    let message: MessageResponse?

    init(
        channel: ChannelDetailPayload? = nil,
        members: [MemberPayload],
        message: MessageResponse? = nil
    ) {
        self.channel = channel
        self.members = members
        self.message = message
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.channel = try container.decodeIfPresent(ChannelDetailPayload.self, forKey: .channel)
        self.members = try container.decodeArrayIgnoringFailures(
            [MemberPayload].self,
            forKey: .members
        )
        self.message = try container.decodeIfPresent(MessageResponse.self, forKey: .message)
    }
}
