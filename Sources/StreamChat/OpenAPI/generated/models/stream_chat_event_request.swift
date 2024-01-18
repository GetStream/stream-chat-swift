//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatEventRequest: Codable, Hashable {
    public var type: String
    
    public var custom: [String: RawJSON]?
    
    public var parentId: String?
    
    public init(type: String, custom: [String: RawJSON]?, parentId: String?) {
        self.type = type
        
        self.custom = custom
        
        self.parentId = parentId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case custom
        
        case parentId = "parent_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(parentId, forKey: .parentId)
    }
}
