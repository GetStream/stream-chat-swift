//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGuestResponse: Codable, Hashable {
    public var user: StreamChatUserObject?
    
    public var accessToken: String
    
    public var duration: String
    
    public init(user: StreamChatUserObject?, accessToken: String, duration: String) {
        self.user = user
        
        self.accessToken = accessToken
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case user
        
        case accessToken = "access_token"
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(accessToken, forKey: .accessToken)
        
        try container.encode(duration, forKey: .duration)
    }
}
