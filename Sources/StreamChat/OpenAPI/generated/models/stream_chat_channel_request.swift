//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelRequest: Codable, Hashable {
    public var frozen: Bool?
    
    public var members: [StreamChatChannelMemberRequest?]?
    
    public var team: String?
    
    public var autoTranslationLanguage: String?
    
    public var configOverrides: StreamChatChannelConfigRequest?
    
    public var disabled: Bool?
    
    public var custom: [String: RawJSON]?
    
    public var autoTranslationEnabled: Bool?
    
    public var truncatedById: String?
    
    public init(frozen: Bool?, members: [StreamChatChannelMemberRequest?]?, team: String?, autoTranslationLanguage: String?, configOverrides: StreamChatChannelConfigRequest?, disabled: Bool?, custom: [String: RawJSON]?, autoTranslationEnabled: Bool?, truncatedById: String?) {
        self.frozen = frozen
        
        self.members = members
        
        self.team = team
        
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.configOverrides = configOverrides
        
        self.disabled = disabled
        
        self.custom = custom
        
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.truncatedById = truncatedById
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case frozen
        
        case members
        
        case team
        
        case autoTranslationLanguage = "auto_translation_language"
        
        case configOverrides = "config_overrides"
        
        case disabled
        
        case custom = "Custom"
        
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case truncatedById = "truncated_by_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(configOverrides, forKey: .configOverrides)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(truncatedById, forKey: .truncatedById)
    }
}
