//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatImageDataRequest: Codable, Hashable {
    public var frames: String?
    
    public var height: String?
    
    public var size: String?
    
    public var url: String?
    
    public var width: String?
    
    public init(frames: String?, height: String?, size: String?, url: String?, width: String?) {
        self.frames = frames
        
        self.height = height
        
        self.size = size
        
        self.url = url
        
        self.width = width
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case frames
        
        case height
        
        case size
        
        case url
        
        case width
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(frames, forKey: .frames)
        
        try container.encode(height, forKey: .height)
        
        try container.encode(size, forKey: .size)
        
        try container.encode(url, forKey: .url)
        
        try container.encode(width, forKey: .width)
    }
}
