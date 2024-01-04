//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatMatchResponse: Codable, Hashable {
    public var text: String
    
    public var type: String
    
    public init(text: String, type: String) {
        self.text = text
        
        self.type = type
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case text
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(text, forKey: .text)
        
        try container.encode(type, forKey: .type)
    }
}
