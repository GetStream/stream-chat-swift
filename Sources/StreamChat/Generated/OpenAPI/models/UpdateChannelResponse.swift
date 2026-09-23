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

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case members
        case message
    }
}
