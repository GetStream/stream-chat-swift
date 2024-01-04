//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEgressRTMPResponse: Codable, Hashable {
    public var streamKey: String
    
    public var url: String
    
    public var name: String
    
    public init(streamKey: String, url: String, name: String) {
        self.streamKey = streamKey
        
        self.url = url
        
        self.name = name
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case streamKey = "stream_key"
        
        case url
        
        case name
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(streamKey, forKey: .streamKey)
        
        try container.encode(url, forKey: .url)
        
        try container.encode(name, forKey: .name)
    }
}
