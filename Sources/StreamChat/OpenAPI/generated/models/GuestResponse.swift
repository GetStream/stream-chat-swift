//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct GuestResponse: Codable, Hashable {
    public var accessToken: String
    
    public var duration: String
    
    public var user: UserObject? = nil
    
    public init(accessToken: String, duration: String, user: UserObject? = nil) {
        self.accessToken = accessToken
        
        self.duration = duration
        
        self.user = user
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case accessToken = "access_token"
        
        case duration
        
        case user
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(accessToken, forKey: .accessToken)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(user, forKey: .user)
    }
}
