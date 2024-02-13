//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelRequest: Codable, Hashable {
    public var autoTranslationEnabled: Bool? = nil
    public var autoTranslationLanguage: String? = nil
    public var disabled: Bool? = nil
    public var frozen: Bool? = nil
    public var team: String? = nil
    public var truncatedById: String? = nil
    public var members: [ChannelMemberRequest?]? = nil
    public var configOverrides: ChannelConfigRequest? = nil
    public var custom: [String: RawJSON]? = nil

    public init(autoTranslationEnabled: Bool? = nil, autoTranslationLanguage: String? = nil, disabled: Bool? = nil, frozen: Bool? = nil, team: String? = nil, truncatedById: String? = nil, members: [ChannelMemberRequest?]? = nil, configOverrides: ChannelConfigRequest? = nil, custom: [String: RawJSON]? = nil) {
        self.autoTranslationEnabled = autoTranslationEnabled
        self.autoTranslationLanguage = autoTranslationLanguage
        self.disabled = disabled
        self.frozen = frozen
        self.team = team
        self.truncatedById = truncatedById
        self.members = members
        self.configOverrides = configOverrides
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationEnabled = "auto_translation_enabled"
        case autoTranslationLanguage = "auto_translation_language"
        case disabled
        case frozen
        case team
        case truncatedById = "truncated_by_id"
        case members
        case configOverrides = "config_overrides"
        case custom = "Custom"
    }
}
