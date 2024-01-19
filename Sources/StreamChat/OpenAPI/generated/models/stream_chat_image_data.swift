//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatImageData: Codable, Hashable {
    public var width: String
    
    public var frames: String
    
    public var height: String
    
    public var size: String
    
    public var url: String
    
    public init(width: String, frames: String, height: String, size: String, url: String) {
        self.width = width
        
        self.frames = frames
        
        self.height = height
        
        self.size = size
        
        self.url = url
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case width
        
        case frames
        
        case height
        
        case size
        
        case url
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(width, forKey: .width)
        
        try container.encode(frames, forKey: .frames)
        
        try container.encode(height, forKey: .height)
        
        try container.encode(size, forKey: .size)
        
        try container.encode(url, forKey: .url)
    }
}
