//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct DeleteChannelResponse: Codable, Hashable {
    public var duration: String
    public var channel: ChannelResponse? = nil

    public init(duration: String, channel: ChannelResponse? = nil) {
        self.duration = duration
        self.channel = channel
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case channel
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(duration, forKey: .duration)
        try container.encode(channel, forKey: .channel)
    }
}
