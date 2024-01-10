//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAgoraCall: Codable, Hashable {
    public var channel: String
    
    public init(channel: String) {
        self.channel = channel
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channel
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channel, forKey: .channel)
    }
}
