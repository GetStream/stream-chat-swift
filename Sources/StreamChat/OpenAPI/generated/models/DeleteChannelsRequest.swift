//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct DeleteChannelsRequest: Codable, Hashable {
    public var hardDelete: Bool? = nil
    public var cids: [String]? = nil

    public init(hardDelete: Bool? = nil, cids: [String]? = nil) {
        self.hardDelete = hardDelete
        self.cids = cids
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case hardDelete = "hard_delete"
        case cids
    }
}
