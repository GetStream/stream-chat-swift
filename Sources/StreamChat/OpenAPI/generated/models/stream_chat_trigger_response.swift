//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatTriggerResponse: Codable, Hashable {
    public var type: String
    
    public var options: [String: RawJSON]?
    
    public init(type: String, options: [String: RawJSON]?) {
        self.type = type
        
        self.options = options
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case options
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(options, forKey: .options)
    }
}
