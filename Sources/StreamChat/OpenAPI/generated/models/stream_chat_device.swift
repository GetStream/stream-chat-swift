//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatDevice: Codable, Hashable {
    public var voip: Bool?
    
    public var createdAt: Date
    
    public var disabled: Bool?
    
    public var disabledReason: String?
    
    public var id: String
    
    public var pushProvider: String
    
    public var pushProviderName: String?
    
    public init(voip: Bool?, createdAt: Date, disabled: Bool?, disabledReason: String?, id: String, pushProvider: String, pushProviderName: String?) {
        self.voip = voip
        
        self.createdAt = createdAt
        
        self.disabled = disabled
        
        self.disabledReason = disabledReason
        
        self.id = id
        
        self.pushProvider = pushProvider
        
        self.pushProviderName = pushProviderName
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case voip
        
        case createdAt = "created_at"
        
        case disabled
        
        case disabledReason = "disabled_reason"
        
        case id
        
        case pushProvider = "push_provider"
        
        case pushProviderName = "push_provider_name"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(voip, forKey: .voip)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(disabledReason, forKey: .disabledReason)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(pushProvider, forKey: .pushProvider)
        
        try container.encode(pushProviderName, forKey: .pushProviderName)
    }
}
