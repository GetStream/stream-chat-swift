//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatLabelThresholds: Codable, Hashable {
    public var flag: Double?
    
    public var block: Double?
    
    public init(flag: Double?, block: Double?) {
        self.flag = flag
        
        self.block = block
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case flag
        
        case block
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(flag, forKey: .flag)
        
        try container.encode(block, forKey: .block)
    }
}
