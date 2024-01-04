//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateUserPartialRequest: Codable, Hashable {
    public var set: [String: RawJSON]
    
    public var unset: [String]
    
    public var id: String
    
    public init(set: [String: RawJSON], unset: [String], id: String) {
        self.set = set
        
        self.unset = unset
        
        self.id = id
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case set
        
        case unset
        
        case id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(set, forKey: .set)
        
        try container.encode(unset, forKey: .unset)
        
        try container.encode(id, forKey: .id)
    }
}
