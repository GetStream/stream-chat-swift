//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatImageDataRequest: Codable, Hashable {
    public var height: String?
    
    public var size: String?
    
    public var url: String?
    
    public var width: String?
    
    public var frames: String?
    
    public init(height: String?, size: String?, url: String?, width: String?, frames: String?) {
        self.height = height
        
        self.size = size
        
        self.url = url
        
        self.width = width
        
        self.frames = frames
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case height
        
        case size
        
        case url
        
        case width
        
        case frames
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(height, forKey: .height)
        
        try container.encode(size, forKey: .size)
        
        try container.encode(url, forKey: .url)
        
        try container.encode(width, forKey: .width)
        
        try container.encode(frames, forKey: .frames)
    }
}
