//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelStopWatchingRequest: Codable, Hashable {
    public var connectionId: String?
    
    public init(connectionId: String?) {
        self.connectionId = connectionId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case connectionId = "connection_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(connectionId, forKey: .connectionId)
    }
}
