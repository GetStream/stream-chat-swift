//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSortParam: Codable, Hashable {
    public var direction: Int?
    
    public var field: String?
    
    public init(direction: Int?, field: String?) {
        self.direction = direction
        
        self.field = field
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case direction
        
        case field
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(direction, forKey: .direction)
        
        try container.encode(field, forKey: .field)
    }
}
