//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEgressResponse: Codable, Hashable {
    public var broadcasting: Bool
    
    public var hls: StreamChatEgressHLSResponse?
    
    public var rtmps: [StreamChatEgressRTMPResponse]
    
    public init(broadcasting: Bool, hls: StreamChatEgressHLSResponse?, rtmps: [StreamChatEgressRTMPResponse]) {
        self.broadcasting = broadcasting
        
        self.hls = hls
        
        self.rtmps = rtmps
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case broadcasting
        
        case hls
        
        case rtmps
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(broadcasting, forKey: .broadcasting)
        
        try container.encode(hls, forKey: .hls)
        
        try container.encode(rtmps, forKey: .rtmps)
    }
}
