//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatRecordSettings: Codable, Hashable {
    public var audioOnly: Bool
    
    public var mode: String
    
    public var quality: String
    
    public var layout: StreamChatLayoutSettings? = nil
    
    public init(audioOnly: Bool, mode: String, quality: String, layout: StreamChatLayoutSettings? = nil) {
        self.audioOnly = audioOnly
        
        self.mode = mode
        
        self.quality = quality
        
        self.layout = layout
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audioOnly = "audio_only"
        
        case mode
        
        case quality
        
        case layout
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(audioOnly, forKey: .audioOnly)
        
        try container.encode(mode, forKey: .mode)
        
        try container.encode(quality, forKey: .quality)
        
        try container.encode(layout, forKey: .layout)
    }
}
