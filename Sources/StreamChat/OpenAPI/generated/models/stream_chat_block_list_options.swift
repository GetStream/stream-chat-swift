//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatBlockListOptions: Codable, Hashable {
    public var blocklist: String
    
    public var behavior: String
    
    public init(blocklist: String, behavior: String) {
        self.blocklist = blocklist
        
        self.behavior = behavior
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case blocklist
        
        case behavior
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(blocklist, forKey: .blocklist)
        
        try container.encode(behavior, forKey: .behavior)
    }
}
