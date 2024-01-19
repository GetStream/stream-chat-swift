//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatJoinCallRequest: Codable, Hashable {
    public var data: StreamChatCallRequest?
    
    public var location: String
    
    public var membersLimit: Int?
    
    public var migratingFrom: String?
    
    public var notify: Bool?
    
    public var ring: Bool?
    
    public var create: Bool?
    
    public init(data: StreamChatCallRequest?, location: String, membersLimit: Int?, migratingFrom: String?, notify: Bool?, ring: Bool?, create: Bool?) {
        self.data = data
        
        self.location = location
        
        self.membersLimit = membersLimit
        
        self.migratingFrom = migratingFrom
        
        self.notify = notify
        
        self.ring = ring
        
        self.create = create
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case data
        
        case location
        
        case membersLimit = "members_limit"
        
        case migratingFrom = "migrating_from"
        
        case notify
        
        case ring
        
        case create
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(data, forKey: .data)
        
        try container.encode(location, forKey: .location)
        
        try container.encode(membersLimit, forKey: .membersLimit)
        
        try container.encode(migratingFrom, forKey: .migratingFrom)
        
        try container.encode(notify, forKey: .notify)
        
        try container.encode(ring, forKey: .ring)
        
        try container.encode(create, forKey: .create)
    }
}
