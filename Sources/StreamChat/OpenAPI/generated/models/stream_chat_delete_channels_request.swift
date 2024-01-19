//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatDeleteChannelsRequest: Codable, Hashable {
    public var hardDelete: Bool?
    
    public var cids: [String]?
    
    public init(hardDelete: Bool?, cids: [String]?) {
        self.hardDelete = hardDelete
        
        self.cids = cids
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hardDelete = "hard_delete"
        
        case cids
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(hardDelete, forKey: .hardDelete)
        
        try container.encode(cids, forKey: .cids)
    }
}
