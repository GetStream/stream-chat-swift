//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBlockListOptions: Codable, Hashable {
    public var behavior: String
    
    public var blocklist: String
    
    public init(behavior: String, blocklist: String) {
        self.behavior = behavior
        
        self.blocklist = blocklist
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case behavior
        
        case blocklist
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(behavior, forKey: .behavior)
        
        try container.encode(blocklist, forKey: .blocklist)
    }
}
