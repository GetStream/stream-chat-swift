//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBroadcastSettingsRequest: Codable, Hashable {
    public var enabled: Bool?
    
    public var hls: StreamChatHLSSettingsRequest?
    
    public init(enabled: Bool?, hls: StreamChatHLSSettingsRequest?) {
        self.enabled = enabled
        
        self.hls = hls
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        
        case hls
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(enabled, forKey: .enabled)
        
        try container.encode(hls, forKey: .hls)
    }
}
