//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatChannelRequest: Codable, Hashable {
    public var autoTranslationEnabled: Bool?
    
    public var configOverrides: StreamChatChannelConfigRequest?
    
    public var disabled: Bool?
    
    public var frozen: Bool?
    
    public var custom: [String: RawJSON]?
    
    public var autoTranslationLanguage: String?
    
    public var members: [StreamChatChannelMemberRequest?]?
    
    public var team: String?
    
    public var truncatedById: String?
    
    public init(autoTranslationEnabled: Bool?, configOverrides: StreamChatChannelConfigRequest?, disabled: Bool?, frozen: Bool?, custom: [String: RawJSON]?, autoTranslationLanguage: String?, members: [StreamChatChannelMemberRequest?]?, team: String?, truncatedById: String?) {
        self.autoTranslationEnabled = autoTranslationEnabled
        
        self.configOverrides = configOverrides
        
        self.disabled = disabled
        
        self.frozen = frozen
        
        self.custom = custom
        
        self.autoTranslationLanguage = autoTranslationLanguage
        
        self.members = members
        
        self.team = team
        
        self.truncatedById = truncatedById
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationEnabled = "auto_translation_enabled"
        
        case configOverrides = "config_overrides"
        
        case disabled
        
        case frozen
        
        case custom
        
        case autoTranslationLanguage = "auto_translation_language"
        
        case members
        
        case team
        
        case truncatedById = "truncated_by_id"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(autoTranslationEnabled, forKey: .autoTranslationEnabled)
        
        try container.encode(configOverrides, forKey: .configOverrides)
        
        try container.encode(disabled, forKey: .disabled)
        
        try container.encode(frozen, forKey: .frozen)
        
        try container.encode(custom, forKey: .custom)
        
        try container.encode(autoTranslationLanguage, forKey: .autoTranslationLanguage)
        
        try container.encode(members, forKey: .members)
        
        try container.encode(team, forKey: .team)
        
        try container.encode(truncatedById, forKey: .truncatedById)
    }
}
