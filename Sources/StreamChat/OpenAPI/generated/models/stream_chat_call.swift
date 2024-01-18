//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatCall: Codable, Hashable {
    public var agora: StreamChatAgoraCall?
    
    public var hms: StreamChatHMSCall?
    
    public var id: String
    
    public var provider: String
    
    public var type: String
    
    public init(agora: StreamChatAgoraCall?, hms: StreamChatHMSCall?, id: String, provider: String, type: String) {
        self.agora = agora
        
        self.hms = hms
        
        self.id = id
        
        self.provider = provider
        
        self.type = type
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case agora
        
        case hms
        
        case id
        
        case provider
        
        case type
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(agora, forKey: .agora)
        
        try container.encode(hms, forKey: .hms)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(provider, forKey: .provider)
        
        try container.encode(type, forKey: .type)
    }
}
