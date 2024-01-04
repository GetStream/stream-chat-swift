//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCommandRequest: Codable, Hashable {
    public var description: String?
    
    public var name: String?
    
    public var set: String?
    
    public var args: String?
    
    public init(description: String?, name: String?, set: String?, args: String?) {
        self.description = description
        
        self.name = name
        
        self.set = set
        
        self.args = args
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case description
        
        case name
        
        case set
        
        case args
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(description, forKey: .description)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(set, forKey: .set)
        
        try container.encode(args, forKey: .args)
    }
}
