//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatDeviceRequest: Codable, Hashable {
    public var disabledReason: String?
    
    public var id: String
    
    public var pushProvider: String
    
    public var pushProviderName: String?
    
    public var userId: String?
    
    public var voip: Bool?
    
    public var createdAt: String?
    
    public var disabled: Bool?
    
    public init(disabledReason: String?, id: String, pushProvider: String, pushProviderName: String?, userId: String?, voip: Bool?, createdAt: String?, disabled: Bool?) {
        self.disabledReason = disabledReason
        
        self.id = id
        
        self.pushProvider = pushProvider
        
        self.pushProviderName = pushProviderName
        
        self.userId = userId
        
        self.voip = voip
        
        self.createdAt = createdAt
        
        self.disabled = disabled
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case disabledReason = "disabled_reason"
        
        case id
        
        case pushProvider = "push_provider"
        
        case pushProviderName = "push_provider_name"
        
        case userId = "user_id"
        
        case voip
        
        case createdAt = "created_at"
        
        case disabled
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(disabledReason, forKey: .disabledReason)
        
        try container.encode(id, forKey: .id)
        
        try container.encode(pushProvider, forKey: .pushProvider)
        
        try container.encode(pushProviderName, forKey: .pushProviderName)
        
        try container.encode(userId, forKey: .userId)
        
        try container.encode(voip, forKey: .voip)
        
        try container.encode(createdAt, forKey: .createdAt)
        
        try container.encode(disabled, forKey: .disabled)
    }
}
