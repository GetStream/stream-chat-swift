//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTargetResolutionRequest: Codable, Hashable {
    public var height: Int?
    
    public var width: Int?
    
    public var bitrate: Int?
    
    public init(height: Int?, width: Int?, bitrate: Int?) {
        self.height = height
        
        self.width = width
        
        self.bitrate = bitrate
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case height
        
        case width
        
        case bitrate
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(height, forKey: .height)
        
        try container.encode(width, forKey: .width)
        
        try container.encode(bitrate, forKey: .bitrate)
    }
}
