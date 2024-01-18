//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelRequest: Codable, Hashable {
    public var truncatedById: String?
    
    public var custom: [String: RawJSON]?
    
    public var autoTranslationLanguage: String?
    
    public var configOverrides: StreamChatChannelConfigRequest?
    
    public var disabled: Bool?
    
    public var frozen: Bool?
    
    public var autoTranslationEnabled: Bool?
    
    public var members: [StreamChatChannelMemberRequest?]?
    
    public var team: String?
    
    public init(truncatedById: String?, custom: [String: RawJSON]?, autoTranslationLanguage: String?, configOverrides: StreamChatChannelConfigRequest?, disabled: Bool?, frozen: Bool?, autoTranslationEnabled: Bool?, members: [StreamChatChannelMemberRequest?]?, team: String?) {
        self.truncatedById = truncatedById
        
        self.custom = custom
        
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.configOverrides = configOverrides
        
        self.disabled = disabled
        
        self.frozen = frozen
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.members = members
        
        self.team = team
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case truncatedById = "truncated_by_id"
        
        case custom = "Custom"
        
        case autoTranslationLanguage = "auto_translation_language"
        
        case configOverrides = "config_overrides"
        
        case disabled
        
        case frozen
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case members
        
        case team
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(truncatedById, forKey: .truncatedById)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(configOverrides, forKey: .configOverrides)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(team, forKey: .team)
    }
}
