//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatImagesRequest: Codable, Hashable {
    public var fixedHeightDownsampled: StreamChatImageDataRequest?
    
    public var fixedHeightStill: StreamChatImageDataRequest?
    
    public var fixedWidth: StreamChatImageDataRequest?
    
    public var fixedWidthDownsampled: StreamChatImageDataRequest?
    
    public var fixedWidthStill: StreamChatImageDataRequest?
    
    public var original: StreamChatImageDataRequest?
    
    public var fixedHeight: StreamChatImageDataRequest?
    
    public init(fixedHeightDownsampled: StreamChatImageDataRequest?, fixedHeightStill: StreamChatImageDataRequest?, fixedWidth: StreamChatImageDataRequest?, fixedWidthDownsampled: StreamChatImageDataRequest?, fixedWidthStill: StreamChatImageDataRequest?, original: StreamChatImageDataRequest?, fixedHeight: StreamChatImageDataRequest?) {
        self.fixedHeightDownsampled = fixedHeightDownsampled
        
        self.fixedHeightStill = fixedHeightStill
        
        self.fixedWidth = fixedWidth
        
        self.fixedWidthDownsampled = fixedWidthDownsampled
        
        self.fixedWidthStill = fixedWidthStill
        
        self.original = original
        
        self.fixedHeight = fixedHeight
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case fixedHeightDownsampled = "fixed_height_downsampled"
        
        case fixedHeightStill = "fixed_height_still"
        
        case fixedWidth = "fixed_width"
        
        case fixedWidthDownsampled = "fixed_width_downsampled"
        
        case fixedWidthStill = "fixed_width_still"
        
        case original
        
        case fixedHeight = "fixed_height"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(fixedHeightDownsampled, forKey: .fixedHeightDownsampled)
        
        try container.encode(fixedHeightStill, forKey: .fixedHeightStill)
        
        try container.encode(fixedWidth, forKey: .fixedWidth)
        
        try container.encode(fixedWidthDownsampled, forKey: .fixedWidthDownsampled)
        
        try container.encode(fixedWidthStill, forKey: .fixedWidthStill)
        
        try container.encode(original, forKey: .original)
        
        try container.encode(fixedHeight, forKey: .fixedHeight)
    }
}
