//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGuestResponse: Codable, Hashable {
    public var duration: String
    
    public var user: StreamChatUserObject?
    
    public var accessToken: String
    
    public init(duration: String, user: StreamChatUserObject?, accessToken: String) {
        self.duration = duration
        
        self.user = user
        
        self.accessToken = accessToken
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        
        case user
        
        case accessToken = "access_token"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(user, forKey: .user)
        
        try container.encode(accessToken, forKey: .accessToken)
    }
}
