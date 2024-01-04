//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatGetOrCreateCallRequest: Codable, Hashable {
    public var data: StreamChatCallRequest?
    
    public var membersLimit: Int?
    
    public var notify: Bool?
    
    public var ring: Bool?
    
    public init(data: StreamChatCallRequest?, membersLimit: Int?, notify: Bool?, ring: Bool?) {
        self.data = data
        
        self.membersLimit = membersLimit
        
        self.notify = notify
        
        self.ring = ring
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case data
        
        case membersLimit = "members_limit"
        
        case notify
        
        case ring
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(data, forKey: .data)
        
        try container.encode(membersLimit, forKey: .membersLimit)
        
        try container.encode(notify, forKey: .notify)
        
        try container.encode(ring, forKey: .ring)
    }
}
