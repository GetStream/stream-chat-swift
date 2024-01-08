//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatDevice: Codable, Hashable {
    public var pushProviderName: String?
    
    public var voip: Bool?
    
    public var createdAt: String
    
    public var disabled: Bool?
    
    public var disabledReason: String?
    
    public var id: String
    
    public var pushProvider: String
    
    public init(pushProviderName: String?, voip: Bool?, createdAt: String, disabled: Bool?, disabledReason: String?, id: String, pushProvider: String) {
        self.pushProviderName = pushProviderName
        
        self.voip = voip
        
        self.createdAt = createdAt
        
        self.disabled = disabled
        
        self.disabledReason = disabledReason
        
        self.id = id
        
        self.pushProvider = pushProvider
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case pushProviderName = "push_provider_name"
        
        case voip
        
        case createdAt = "created_at"
        
        case disabled
        
        case disabledReason = "disabled_reason"
        
        case id
        
        case pushProvider = "push_provider"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(pushProviderName, forKey: .pushProviderName)
        
        try container.encode(voip, forKey: .voip)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(disabledReason, forKey: .disabledReason)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(pushProvider, forKey: .pushProvider)
    }
}
