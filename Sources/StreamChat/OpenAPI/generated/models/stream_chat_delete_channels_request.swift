//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatDeleteChannelsRequest: Codable, Hashable {
    public var cids: [String]?
    
    public var hardDelete: Bool?
    
    public init(cids: [String]?, hardDelete: Bool?) {
        self.cids = cids
        
        self.hardDelete = hardDelete
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cids
        
        case hardDelete = "hard_delete"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(cids, forKey: .cids)
        
        try container.encode(hardDelete, forKey: .hardDelete)
    }
}
