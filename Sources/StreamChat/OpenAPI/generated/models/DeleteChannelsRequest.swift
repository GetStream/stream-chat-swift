//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct DeleteChannelsRequest: Codable, Hashable {
    public var cids: [String]
    public var hardDelete: Bool? = nil

    public init(cids: [String], hardDelete: Bool? = nil) {
        self.cids = cids
        self.hardDelete = hardDelete
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case cids
        case hardDelete = "hard_delete"
    }
}
