//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelsResponse: Codable, Hashable {
    public var duration: String
    public var channels: [ChannelStateResponseFields]

    public init(duration: String, channels: [ChannelStateResponseFields]) {
        self.duration = duration
        self.channels = channels
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case channels
    }
}