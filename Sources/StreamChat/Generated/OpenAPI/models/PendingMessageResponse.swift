//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class PendingMessageResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse?
    var message: MessageResponse?
    var metadata: [String: String]?
    var user: UserResponse?

    init(channel: ChannelResponse? = nil, message: MessageResponse? = nil, metadata: [String: String]? = nil, user: UserResponse? = nil) {
        self.channel = channel
        self.message = message
        self.metadata = metadata
        self.user = user
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case message
        case metadata
        case user
    }

    static func == (lhs: PendingMessageResponse, rhs: PendingMessageResponse) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.message == rhs.message &&
            lhs.metadata == rhs.metadata &&
            lhs.user == rhs.user
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(message)
        hasher.combine(metadata)
        hasher.combine(user)
    }
}
