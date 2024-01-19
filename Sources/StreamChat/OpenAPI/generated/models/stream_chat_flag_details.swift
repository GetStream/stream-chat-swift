//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatFlagDetails: Codable, Hashable {
    public var extra: [String: RawJSON]
    
    public var automod: StreamChatAutomodDetails?
    
    public var originalText: String
    
    public init(extra: [String: RawJSON], automod: StreamChatAutomodDetails?, originalText: String) {
        self.extra = extra
        
        self.automod = automod
        
        self.originalText = originalText
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case extra = "Extra"
        
        case automod
        
        case originalText = "original_text"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(extra, forKey: .extra)
        
        try container.encode(automod, forKey: .automod)
        
        try container.encode(originalText, forKey: .originalText)
    }
}
