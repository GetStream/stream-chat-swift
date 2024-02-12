//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct EventRequest: Codable, Hashable {
    public var type: String
    
    public var parentId: String? = nil
    
    public var custom: [String: RawJSON]? = nil
    
    public init(type: String, parentId: String? = nil, custom: [String: RawJSON]? = nil) {
        self.type = type
        
        self.parentId = parentId
        
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        
        case parentId = "parent_id"
        
        case custom
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(parentId, forKey: .parentId)
        
        try container.encode(custom, forKey: .custom)
    }
}
