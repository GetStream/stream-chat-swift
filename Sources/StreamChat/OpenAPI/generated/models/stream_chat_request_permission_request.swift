//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatRequestPermissionRequest: Codable, Hashable {
    public var permissions: [String]
    
    public init(permissions: [String]) {
        self.permissions = permissions
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case permissions
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(permissions, forKey: .permissions)
    }
}
