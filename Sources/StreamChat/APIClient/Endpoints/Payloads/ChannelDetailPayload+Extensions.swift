//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

protocol ChannelCustomCommonFields {
    var custom: [String: RawJSON] { get }
}

extension ChannelDetailPayload: ChannelCustomCommonFields {}
extension ChannelPartialUpdateResponse: ChannelCustomCommonFields {}

// Generated properties are slightly different from the previously hand-written ones.
extension ChannelCustomCommonFields {
    // `name` and `image` arrive in `custom`, but they are channel fields, not user extra data.
    private static var nameAndImageKeys: [String] { [
        ChannelCodingKeys.name.rawValue,
        ChannelCodingKeys.imageURL.rawValue
    ] }

    var extraData: [String: RawJSON] { custom.removingValues(forKeys: Self.nameAndImageKeys) }

    var group: String? { custom[GroupedChannelKey.group]?.stringValue.flatMap { $0.isEmpty ? nil : $0 } }

    var imageURL: URL? {
        custom[ChannelCodingKeys.imageURL.rawValue]?.stringValue.flatMap(URL.init(string:))
    }

    var name: String? { custom[ChannelCodingKeys.name.rawValue]?.stringValue }

    var touchedAt: Date? {
        custom[GroupedChannelKey.touchedAt]?.stringValue.flatMap(RFC3339DateFormatter.date(from:))
    }
}

extension ChannelDetailPayload {
    convenience init(
        cid: ChannelId,
        name: String?,
        imageURL: URL?,
        extraData: [String: RawJSON],
        lastMessageAt: Date?,
        createdAt: Date,
        deletedAt: Date?,
        updatedAt: Date,
        truncatedAt: Date?,
        truncatedBy: UserPayload? = nil,
        createdBy: UserPayload?,
        config: ChannelConfig,
        filterTags: [String]?,
        ownCapabilities: [String]?,
        isDisabled: Bool,
        isFrozen: Bool,
        isBlocked: Bool?,
        isHidden: Bool?,
        members: [MemberPayload]?,
        memberCount: Int?,
        messageCount: Int?,
        team: TeamId?,
        cooldownDuration: Int?,
        autoTranslationEnabled: Bool? = nil,
        autoTranslationLanguage: String? = nil
    ) {
        var custom = extraData
        if let name {
            custom[ChannelCodingKeys.name.rawValue] = .string(name)
        }
        if let imageURL {
            custom[ChannelCodingKeys.imageURL.rawValue] = .string(imageURL.absoluteString)
        }

        self.init(
            autoTranslationEnabled: autoTranslationEnabled,
            autoTranslationLanguage: autoTranslationLanguage,
            blocked: isBlocked,
            cid: cid,
            config: config,
            cooldown: cooldownDuration,
            createdAt: createdAt,
            createdBy: createdBy,
            custom: custom,
            deletedAt: deletedAt,
            disabled: isDisabled,
            filterTags: filterTags,
            frozen: isFrozen,
            hidden: isHidden,
            id: cid.id,
            lastMessageAt: lastMessageAt,
            memberCount: memberCount,
            members: members,
            messageCount: messageCount,
            ownCapabilities: ownCapabilities?.map(ChannelCapability.init(rawValue:)),
            team: team,
            truncatedAt: truncatedAt,
            truncatedBy: truncatedBy,
            type: cid.type.rawValue,
            updatedAt: updatedAt
        )
    }
}
