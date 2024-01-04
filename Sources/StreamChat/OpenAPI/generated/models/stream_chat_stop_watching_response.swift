//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatStopWatchingResponse: Codable, Hashable {
    public var duration: String
    
    public init(duration: String) {
        self.duration = duration
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
    }
}
