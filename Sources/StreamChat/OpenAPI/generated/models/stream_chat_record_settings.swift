//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatRecordSettings: Codable, Hashable {
    public var quality: String
    
    public var audioOnly: Bool
    
    public var layout: StreamChatLayoutSettings?
    
    public var mode: String
    
    public init(quality: String, audioOnly: Bool, layout: StreamChatLayoutSettings?, mode: String) {
        self.quality = quality
        
        self.audioOnly = audioOnly
        
        self.layout = layout
        
        self.mode = mode
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case quality
        
        case audioOnly = "audio_only"
        
        case layout
        
        case mode
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(quality, forKey: .quality)
        
        try container.encode(audioOnly, forKey: .audioOnly)
        
        try container.encode(layout, forKey: .layout)
        
        try container.encode(mode, forKey: .mode)
    }
}
