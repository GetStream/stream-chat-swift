//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCall: Codable, Hashable {
    public var provider: String
    
    public var type: String
    
    public var agora: StreamChatAgoraCall?
    
    public var hms: StreamChatHMSCall?
    
    public var id: String
    
    public init(provider: String, type: String, agora: StreamChatAgoraCall?, hms: StreamChatHMSCall?, id: String) {
        self.provider = provider
        
        self.type = type
        
        self.agora = agora
        
        self.hms = hms
        
        self.id = id
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case provider
        
        case type
        
        case agora
        
        case hms
        
        case id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(provider, forKey: .provider)
        
        try container.encode(type, forKey: .type)
        
        try container.encode(agora, forKey: .agora)
        
        try container.encode(hms, forKey: .hms)
        
        try container.encode(id, forKey: .id)
    }
}
