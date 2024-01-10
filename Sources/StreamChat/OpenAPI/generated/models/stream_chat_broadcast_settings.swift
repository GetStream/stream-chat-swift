//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBroadcastSettings: Codable, Hashable {
    public var hls: StreamChatHLSSettings
    
    public var enabled: Bool
    
    public init(hls: StreamChatHLSSettings, enabled: Bool) {
        self.hls = hls
        
        self.enabled = enabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hls
        
        case enabled
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(hls, forKey: .hls)
        
        try container.encode(enabled, forKey: .enabled)
    }
}
