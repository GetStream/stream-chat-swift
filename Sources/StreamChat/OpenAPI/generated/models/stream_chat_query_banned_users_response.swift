//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatQueryBannedUsersResponse: Codable, Hashable {
    public var bans: [StreamChatBanResponse?]
    
    public var duration: String
    
    public init(bans: [StreamChatBanResponse?], duration: String) {
        self.bans = bans
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case bans
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(bans, forKey: .bans)
        
        try container.encode(duration, forKey: .duration)
    }
}
