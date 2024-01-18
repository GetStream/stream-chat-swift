//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatImageSizeRequest: Codable, Hashable {
    public var height: Int?
    
    public var resize: String?
    
    public var width: Int?
    
    public var crop: String?
    
    public init(height: Int?, resize: String?, width: Int?, crop: String?) {
        self.height = height
        
        self.resize = resize
        
        self.width = width
        
        self.crop = crop
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case height
        
        case resize
        
        case width
        
        case crop
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(height, forKey: .height)
        
        try container.encode(resize, forKey: .resize)
        
        try container.encode(width, forKey: .width)
        
        try container.encode(crop, forKey: .crop)
    }
}
