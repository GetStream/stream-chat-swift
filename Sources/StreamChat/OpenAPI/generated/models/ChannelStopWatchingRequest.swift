//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelStopWatchingRequest: Codable, Hashable {
    public var connectionId: String? = nil
    
    public init(connectionId: String? = nil) {
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
