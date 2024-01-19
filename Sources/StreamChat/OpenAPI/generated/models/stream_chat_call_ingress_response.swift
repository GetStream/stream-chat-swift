//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCallIngressResponse: Codable, Hashable {
    public var rtmp: StreamChatRTMPIngress
    
    public init(rtmp: StreamChatRTMPIngress) {
        self.rtmp = rtmp
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case rtmp
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(rtmp, forKey: .rtmp)
    }
}
