//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelRequest: Codable, Hashable {
    public var autoTranslationLanguage: String?
    
    public var disabled: Bool?
    
    public var frozen: Bool?
    
    public var team: String?
    
    public var autoTranslationEnabled: Bool?
    
    public var configOverrides: StreamChatChannelConfigRequest?
    
    public var members: [StreamChatChannelMemberRequest?]?
    
    public var truncatedById: String?
    
    public var custom: [String: RawJSON]?
    
    public init(autoTranslationLanguage: String?, disabled: Bool?, frozen: Bool?, team: String?, autoTranslationEnabled: Bool?, configOverrides: StreamChatChannelConfigRequest?, members: [StreamChatChannelMemberRequest?]?, truncatedById: String?, custom: [String: RawJSON]?) {
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.disabled = disabled
        
        self.frozen = frozen
        
        self.team = team
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.configOverrides = configOverrides
        
        self.members = members
        
        self.truncatedById = truncatedById
        
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationLanguage = "auto_translation_language"
        
        case disabled
        
        case frozen
        
        case team
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case configOverrides = "config_overrides"
        
        case members
        
        case truncatedById = "truncated_by_id"
        
        case custom = "Custom"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(configOverrides, forKey: .configOverrides)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(truncatedById, forKey: .truncatedById)
        
        try container.encode(custom, forKey: .custom)
    }
}
