//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class DeleteChannelResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var channel: ChannelResponse?
    /// Duration of the request in milliseconds
    var duration: String

    init(channel: ChannelResponse? = nil, duration: String) {
        self.channel = channel
        self.duration = duration
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
        case duration
    }

    static func == (lhs: DeleteChannelResponse, rhs: DeleteChannelResponse) -> Bool {
        lhs.channel == rhs.channel &&
            lhs.duration == rhs.duration
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(channel)
        hasher.combine(duration)
    }
}
