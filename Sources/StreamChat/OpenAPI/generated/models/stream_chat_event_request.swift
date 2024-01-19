//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEventRequest: Codable, Hashable {
    public var custom: [String: RawJSON]?
    
    public var parentId: String?
    
    public var type: String
    
    public init(custom: [String: RawJSON]?, parentId: String?, type: String) {
        self.custom = custom
        
        self.parentId = parentId
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case custom
        
        case parentId = "parent_id"
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(type, forKey: .type)
    }
}
