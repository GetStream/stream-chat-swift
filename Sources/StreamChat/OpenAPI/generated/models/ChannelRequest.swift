//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelRequest: Codable, Hashable {
    public var autoTranslationEnabled: Bool? = nil
    public var autoTranslationLanguage: String? = nil
    public var createdById: String? = nil
    public var disabled: Bool? = nil
    public var frozen: Bool? = nil
    public var team: String? = nil
    public var truncatedById: String? = nil
    public var invites: [ChannelMemberRequest?]? = nil
    public var members: [ChannelMemberRequest?]? = nil
    public var configOverrides: ChannelConfigRequest? = nil
    public var createdBy: UserObjectRequest? = nil
    public var custom: [String: RawJSON]? = nil

    public init(autoTranslationEnabled: Bool? = nil, autoTranslationLanguage: String? = nil, createdById: String? = nil, disabled: Bool? = nil, frozen: Bool? = nil, team: String? = nil, truncatedById: String? = nil, invites: [ChannelMemberRequest?]? = nil, members: [ChannelMemberRequest?]? = nil, configOverrides: ChannelConfigRequest? = nil, createdBy: UserObjectRequest? = nil, custom: [String: RawJSON]? = nil) {
        self.autoTranslationEnabled = autoTranslationEnabled
        self.autoTranslationLanguage = autoTranslationLanguage
        self.createdById = createdById
        self.disabled = disabled
        self.frozen = frozen
        self.team = team
        self.truncatedById = truncatedById
        self.invites = invites
        self.members = members
        self.configOverrides = configOverrides
        self.createdBy = createdBy
        self.custom = custom
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case autoTranslationEnabled = "auto_translation_enabled"
        case autoTranslationLanguage = "auto_translation_language"
        case createdById = "created_by_id"
        case disabled
        case frozen
        case team
        case truncatedById = "truncated_by_id"
        case invites
        case members
        case configOverrides = "config_overrides"
        case createdBy = "created_by"
        case custom = "Custom"
    }
}
