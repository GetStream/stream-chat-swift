//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTargetResolution: Codable, Hashable {
    public var width: Int
    
    public var bitrate: Int
    
    public var height: Int
    
    public init(width: Int, bitrate: Int, height: Int) {
        self.width = width
        
        self.bitrate = bitrate
        
        self.height = height
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case width
        
        case bitrate
        
        case height
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(width, forKey: .width)
        
        try container.encode(bitrate, forKey: .bitrate)
        
        try container.encode(height, forKey: .height)
    }
}
