//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTranscriptionSettings: Codable, Hashable {
    public var mode: String
    
    public var closedCaptionMode: String
    
    public init(mode: String, closedCaptionMode: String) {
        self.mode = mode
        
        self.closedCaptionMode = closedCaptionMode
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case mode
        
        case closedCaptionMode = "closed_caption_mode"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(mode, forKey: .mode)
        
        try container.encode(closedCaptionMode, forKey: .closedCaptionMode)
    }
}
