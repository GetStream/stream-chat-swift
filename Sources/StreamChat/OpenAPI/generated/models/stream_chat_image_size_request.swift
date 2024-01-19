//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatImageSizeRequest: Codable, Hashable {
    public var resize: String?
    
    public var width: Int?
    
    public var crop: String?
    
    public var height: Int?
    
    public init(resize: String?, width: Int?, crop: String?, height: Int?) {
        self.resize = resize
        
        self.width = width
        
        self.crop = crop
        
        self.height = height
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case resize
        
        case width
        
        case crop
        
        case height
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(resize, forKey: .resize)
        
        try container.encode(width, forKey: .width)
        
        try container.encode(crop, forKey: .crop)
        
        try container.encode(height, forKey: .height)
    }
}
