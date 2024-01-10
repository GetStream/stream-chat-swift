//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUpdateUserPartialRequest: Codable, Hashable {
    public var id: String
    
    public var set: [String: RawJSON]
    
    public var unset: [String]
    
    public init(id: String, set: [String: RawJSON], unset: [String]) {
        self.id = id
        
        self.set = set
        
        self.unset = unset
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
        
        case set
        
        case unset
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(set, forKey: .set)
        
        try container.encode(unset, forKey: .unset)
    }
}
