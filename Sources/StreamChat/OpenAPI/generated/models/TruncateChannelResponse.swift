//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct TruncateChannelResponse: Codable, Hashable {
    public var duration: String
    public var channel: ChannelResponse? = nil
    public var message: Message? = nil

    public init(duration: String, channel: ChannelResponse? = nil, message: Message? = nil) {
        self.duration = duration
        self.channel = channel
        self.message = message
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case channel
        case message
    }
}
