//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEgressRTMPResponse: Codable, Hashable {
    public var name: String
    
    public var streamKey: String
    
    public var url: String
    
    public init(name: String, streamKey: String, url: String) {
        self.name = name
        
        self.streamKey = streamKey
        
        self.url = url
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        
        case streamKey = "stream_key"
        
        case url
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(streamKey, forKey: .streamKey)
        
        try container.encode(url, forKey: .url)
    }
}
