//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetOrCreateCallRequest: Codable, Hashable {
    public var membersLimit: Int?
    
    public var notify: Bool?
    
    public var ring: Bool?
    
    public var data: StreamChatCallRequest?
    
    public init(membersLimit: Int?, notify: Bool?, ring: Bool?, data: StreamChatCallRequest?) {
        self.membersLimit = membersLimit
        
        self.notify = notify
        
        self.ring = ring
        
        self.data = data
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case membersLimit = "members_limit"
        
        case notify
        
        case ring
        
        case data
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(membersLimit, forKey: .membersLimit)
        
        try container.encode(notify, forKey: .notify)
        
        try container.encode(ring, forKey: .ring)
        
        try container.encode(data, forKey: .data)
    }
}
