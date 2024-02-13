//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct BlockListOptions: Codable, Hashable {
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
}
