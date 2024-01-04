//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatModerationResponseRequest: Codable, Hashable {
    public var toxic: Double?
    
    public var action: String?
    
//    public var automodResponse: StreamChat?
    
    public var explicit: Double?
    
    public var spam: Double?
    
    public init(toxic: Double?, action: String?, explicit: Double?, spam: Double?) {
        self.toxic = toxic
        
        self.action = action
        
//        self.automodResponse = automodResponse
        
        self.explicit = explicit
        
        self.spam = spam
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case toxic
        
        case action
        
//        case automodResponse = "automod_response"
        
        case explicit
        
        case spam
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(toxic, forKey: .toxic)
        
        try container.encode(action, forKey: .action)
        
//        try container.encode(automodResponse, forKey: .automodResponse)
        
        try container.encode(explicit, forKey: .explicit)
        
        try container.encode(spam, forKey: .spam)
    }
}
