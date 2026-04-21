//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class TruncateChannelResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse?
    /// Duration of the request in milliseconds
    var duration: String
    var message: MessageResponse?

    init(channel: ChannelResponse? = nil, duration: String, message: MessageResponse? = nil) {
        self.channel = channel
        self.duration = duration
        self.message = message
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case duration
        case message
    }

    static func == (lhs: TruncateChannelResponse, rhs: TruncateChannelResponse) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.duration == rhs.duration &&
            lhs.message == rhs.message
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(duration)
        hasher.combine(message)
    }
}
