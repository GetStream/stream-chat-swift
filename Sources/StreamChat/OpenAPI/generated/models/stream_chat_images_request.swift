//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatImagesRequest: Codable, Hashable {
    public var fixedHeight: StreamChatImageDataRequest? = nil
    
    public var fixedHeightDownsampled: StreamChatImageDataRequest? = nil
    
    public var fixedHeightStill: StreamChatImageDataRequest? = nil
    
    public var fixedWidth: StreamChatImageDataRequest? = nil
    
    public var fixedWidthDownsampled: StreamChatImageDataRequest? = nil
    
    public var fixedWidthStill: StreamChatImageDataRequest? = nil
    
    public var original: StreamChatImageDataRequest? = nil
    
    public init(fixedHeight: StreamChatImageDataRequest? = nil, fixedHeightDownsampled: StreamChatImageDataRequest? = nil, fixedHeightStill: StreamChatImageDataRequest? = nil, fixedWidth: StreamChatImageDataRequest? = nil, fixedWidthDownsampled: StreamChatImageDataRequest? = nil, fixedWidthStill: StreamChatImageDataRequest? = nil, original: StreamChatImageDataRequest? = nil) {
        self.fixedHeight = fixedHeight
        
        self.fixedHeightDownsampled = fixedHeightDownsampled
        
        self.fixedHeightStill = fixedHeightStill
        
        self.fixedWidth = fixedWidth
        
        self.fixedWidthDownsampled = fixedWidthDownsampled
        
        self.fixedWidthStill = fixedWidthStill
        
        self.original = original
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case fixedHeight = "fixed_height"
        
        case fixedHeightDownsampled = "fixed_height_downsampled"
        
        case fixedHeightStill = "fixed_height_still"
        
        case fixedWidth = "fixed_width"
        
        case fixedWidthDownsampled = "fixed_width_downsampled"
        
        case fixedWidthStill = "fixed_width_still"
        
        case original
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(fixedHeight, forKey: .fixedHeight)
        
        try container.encode(fixedHeightDownsampled, forKey: .fixedHeightDownsampled)
        
        try container.encode(fixedHeightStill, forKey: .fixedHeightStill)
        
        try container.encode(fixedWidth, forKey: .fixedWidth)
        
        try container.encode(fixedWidthDownsampled, forKey: .fixedWidthDownsampled)
        
        try container.encode(fixedWidthStill, forKey: .fixedWidthStill)
        
        try container.encode(original, forKey: .original)
    }
}
