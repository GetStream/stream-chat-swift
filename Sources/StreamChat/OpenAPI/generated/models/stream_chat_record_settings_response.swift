//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatRecordSettingsResponse: Codable, Hashable {
    public var audioOnly: Bool
    
    public var mode: String
    
    public var quality: String
    
    public init(audioOnly: Bool, mode: String, quality: String) {
        self.audioOnly = audioOnly
        
        self.mode = mode
        
        self.quality = quality
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audioOnly = "audio_only"
        
        case mode
        
        case quality
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(audioOnly, forKey: .audioOnly)
        
        try container.encode(mode, forKey: .mode)
        
        try container.encode(quality, forKey: .quality)
    }
}
