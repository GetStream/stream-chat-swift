//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatUnmuteResponse: Codable, Hashable {
    public var duration: String
    
    public var nonExistingUsers: [String]? = nil
    
    public init(duration: String, nonExistingUsers: [String]? = nil) {
        self.duration = duration
        
        self.nonExistingUsers = nonExistingUsers
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case nonExistingUsers = "non_existing_users"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(nonExistingUsers, forKey: .nonExistingUsers)
    }
}
