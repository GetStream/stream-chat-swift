//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PendingMessageResponse: Sendable, Decodable {
    /// Represents channel in chat
    let channel: ChannelDetailPayload?
    /// Represents any chat message
    let message: MessageResponse?
    /// User response object
    let user: UserPayload?

    init(
        channel: ChannelDetailPayload? = nil,
        message: MessageResponse? = nil,
        user: UserPayload? = nil
    ) {
        self.channel = channel
        self.message = message
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case message
        case user
    }
}
