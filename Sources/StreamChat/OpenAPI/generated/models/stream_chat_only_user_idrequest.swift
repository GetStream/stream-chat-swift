//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatOnlyUserIDRequest: Codable, Hashable {
    public var id: String
    
    public init(id: String) {
        self.id = id
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case id
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
    }
}
