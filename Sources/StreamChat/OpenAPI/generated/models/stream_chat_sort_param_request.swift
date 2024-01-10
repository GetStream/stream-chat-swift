//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSortParamRequest: Codable, Hashable {
    public var field: String?
    
    public var direction: Int?
    
    public init(field: String?, direction: Int?) {
        self.field = field
        
        self.direction = direction
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case field
        
        case direction
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(field, forKey: .field)
        
        try container.encode(direction, forKey: .direction)
    }
}
