//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTranscriptionSettingsRequest: Codable, Hashable {
    public var closedCaptionMode: String?
    
    public var mode: String?
    
    public init(closedCaptionMode: String?, mode: String?) {
        self.closedCaptionMode = closedCaptionMode
        
        self.mode = mode
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case closedCaptionMode = "closed_caption_mode"
        
        case mode
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(closedCaptionMode, forKey: .closedCaptionMode)
        
        try container.encode(mode, forKey: .mode)
    }
}
