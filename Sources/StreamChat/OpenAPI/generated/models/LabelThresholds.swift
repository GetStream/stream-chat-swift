//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct LabelThresholds: Codable, Hashable {
    public var block: Double? = nil
    public var flag: Double? = nil

    public init(block: Double? = nil, flag: Double? = nil) {
        self.block = block
        self.flag = flag
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case block
        case flag
    }
}
