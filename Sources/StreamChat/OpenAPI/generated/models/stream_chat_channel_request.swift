//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelRequest: Codable, Hashable {
    public var team: String?
    
    public var autoTranslationLanguage: String?
    
    public var frozen: Bool?
    
    public var configOverrides: StreamChatChannelConfigRequest?
    
    public var disabled: Bool?
    
    public var members: [StreamChatChannelMemberRequest?]?
    
    public var truncatedById: String?
    
    public var custom: [String: RawJSON]?
    
    public var autoTranslationEnabled: Bool?
    
    public init(team: String?, autoTranslationLanguage: String?, frozen: Bool?, configOverrides: StreamChatChannelConfigRequest?, disabled: Bool?, members: [StreamChatChannelMemberRequest?]?, truncatedById: String?, custom: [String: RawJSON]?, autoTranslationEnabled: Bool?) {
        self.team = team
        
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.frozen = frozen
        
        self.configOverrides = configOverrides
        
        self.disabled = disabled
        
        self.members = members
        
        self.truncatedById = truncatedById
        
        self.custom = custom
        
        self.autoTranslationEnabled = autoTranslationEnabled
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case team
        
        case autoTranslationLanguage = "auto_translation_language"
        
        case frozen
        
        case configOverrides = "config_overrides"
        
        case disabled
        
        case members
        
        case truncatedById = "truncated_by_id"
        
        case custom = "Custom"
        
        case autoTranslationEnabled = "auto_translation_enabled"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(configOverrides, forKey: .configOverrides)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(truncatedById, forKey: .truncatedById)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
    }
}
