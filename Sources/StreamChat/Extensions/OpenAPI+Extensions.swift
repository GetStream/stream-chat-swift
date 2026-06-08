//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension UserResponse {
    func asUserResponseCommonFields() -> UserResponseCommonFields {
        UserResponseCommonFields(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            id: id,
            image: image,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }

    func asUserResponsePrivacyFields() -> UserResponsePrivacyFields {
        UserResponsePrivacyFields(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            id: id,
            image: image,
            invisible: nil,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            privacySettings: nil,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }
}

extension UserResponseCommonFields {
    func asUserResponse() -> UserResponse {
        UserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            id: id,
            image: image,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }
}

extension UserResponsePrivacyFields {
    func asUserResponse() -> UserResponse {
        UserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            deletedAt: deletedAt,
            id: id,
            image: image,
            language: language,
            lastActive: lastActive,
            name: name,
            online: online,
            revokeTokensIssuedBefore: revokeTokensIssuedBefore,
            role: role,
            teams: teams,
            teamsRole: teamsRole,
            updatedAt: updatedAt
        )
    }
}

struct MessageListPayload: Decodable {
    let messages: [MessageResponse]
}

private enum MessageTranslationsPayloadKeys {
    static let originalLanguage = "language"
    static let translatedSuffix = "_text"
}

extension Dictionary where Key == String, Value == String {
    var originalLanguage: String? {
        self[MessageTranslationsPayloadKeys.originalLanguage]
    }

    var translated: [TranslationLanguage: String] {
        reduce(into: [:]) { translatedDictionary, keyValuePair in
            let key = keyValuePair.key
            guard key != MessageTranslationsPayloadKeys.originalLanguage else { return }
            guard let suffixRange = key.range(of: MessageTranslationsPayloadKeys.translatedSuffix) else {
                log.warning("Unknown key in `translate` response: \(key), cannot decode", subsystems: .httpRequests)
                return
            }

            let languageCode = String(key.prefix(upTo: suffixRange.lowerBound))
            translatedDictionary[TranslationLanguage(languageCode: languageCode)] = keyValuePair.value
        }
    }

    static func messageTranslations(
        translations: [TranslationLanguage: String]?,
        originalLanguage: String?
    ) -> [String: String]? {
        guard translations != nil || originalLanguage != nil else { return nil }

        var i18n = originalLanguage.map { [MessageTranslationsPayloadKeys.originalLanguage: $0] } ?? [:]
        translations?.forEach {
            i18n[$0.key.languageCode + MessageTranslationsPayloadKeys.translatedSuffix] = $0.value
        }
        return i18n
    }
}

extension ChannelInput {
    convenience init(
        name: String?,
        imageURL: URL?,
        team: String?,
        members: Set<UserId>,
        invites: Set<UserId>,
        filterTags: Set<String>,
        extraData: [String: RawJSON]
    ) {
        self.init(
            custom: Self.customData(name: name, imageURL: imageURL, extraData: extraData),
            filterTags: filterTags.isEmpty ? nil : Array(filterTags),
            invites: invites.isEmpty ? nil : invites.map { ChannelMemberRequest(userId: $0) },
            members: members.union(invites).isEmpty ? nil : members.union(invites).map { ChannelMemberRequest(userId: $0) },
            team: team
        )
    }

    var name: String? {
        custom?["name"]?.stringValue
    }

    var imageURL: URL? {
        custom?["image"]?.stringValue.flatMap(URL.init(string:))
    }

    var extraData: [String: RawJSON] {
        var extraData = custom ?? [:]
        extraData["name"] = nil
        extraData["image"] = nil
        return extraData
    }

    private static func customData(name: String?, imageURL: URL?, extraData: [String: RawJSON]) -> [String: RawJSON]? {
        var custom = extraData
        if let name {
            custom["name"] = .string(name)
        }
        if let imageURL {
            custom["image"] = .string(imageURL.absoluteString)
        }
        return custom.isEmpty ? nil : custom
    }
}

extension OwnUserResponse {
    func asUserResponse() -> UserResponse {
        UserResponse(
            id: id,
            name: name,
            imageURL: imageURL,
            role: userRole,
            teamsRole: teamsRolePayload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActive,
            isOnline: online,
            isInvisible: invisible,
            isBanned: banned,
            teams: teams,
            language: language.isEmpty ? nil : language,
            avgResponseTime: avgResponseTime,
            extraData: custom
        )
    }

    func asFullUserResponse() -> FullUserResponse {
        FullUserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: blockedUserIds ?? [],
            channelMutes: channelMutes,
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            devices: devices,
            id: id,
            image: image,
            invisible: invisible,
            language: language,
            lastActive: lastActive,
            mutes: mutes,
            name: name,
            online: online,
            privacySettings: privacySettings,
            role: role,
            shadowBanned: false,
            teams: teams,
            teamsRole: teamsRole,
            totalUnreadCount: totalUnreadCount,
            unreadChannels: unreadChannels,
            unreadCount: unreadCount,
            unreadThreads: unreadThreads,
            updatedAt: updatedAt
        )
    }

    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }

    var userRole: UserRole {
        UserRole(rawValue: role)
    }

    var teamsRolePayload: [String: UserRole]? {
        teamsRole?.mapValues { UserRole(rawValue: $0) }
    }

    var unreadCountPayload: UnreadCountPayload? {
        UnreadCountPayload(
            channels: unreadChannels,
            messages: unreadCount,
            threads: unreadThreads >= 0 ? unreadThreads : nil
        )
    }

    var blockedUserIdsSet: Set<UserId> {
        Set(blockedUserIds ?? [])
    }

    convenience init(
        id: String,
        name: String?,
        imageURL: URL?,
        role: UserRole,
        teamsRole: [String: UserRole]?,
        createdAt: Date,
        updatedAt: Date,
        deactivatedAt: Date?,
        lastActiveAt: Date?,
        isOnline: Bool,
        isInvisible: Bool,
        isBanned: Bool,
        teams: [TeamId] = [],
        language: String?,
        extraData: [String: RawJSON],
        devices: [DeviceResponse] = [],
        mutedUsers: [UserMuteResponse] = [],
        mutedChannels: [ChannelMute] = [],
        unreadCount: UnreadCountPayload? = nil,
        privacySettings: UserPrivacySettingsPayload? = nil,
        blockedUserIds: Set<UserId> = [],
        pushPreference: PushPreferencesResponse?
    ) {
        self.init(
            avgResponseTime: nil,
            banned: isBanned,
            blockedUserIds: Array(blockedUserIds),
            channelMutes: mutedChannels,
            createdAt: createdAt,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            devices: devices,
            id: id,
            image: imageURL?.absoluteString,
            invisible: isInvisible,
            language: language ?? "",
            lastActive: lastActiveAt,
            mutes: mutedUsers,
            name: name,
            online: isOnline,
            privacySettings: privacySettings?.asPrivacySettingsResponse,
            pushPreferences: pushPreference,
            role: role.rawValue,
            teams: teams,
            teamsRole: teamsRole?.mapValues(\.rawValue),
            totalUnreadCount: unreadCount?.messages ?? 0,
            unreadChannels: unreadCount?.channels ?? 0,
            unreadCount: unreadCount?.messages ?? 0,
            unreadThreads: unreadCount?.threads ?? -1,
            updatedAt: updatedAt
        )
    }
}

extension UserPrivacySettingsPayload {
    var asPrivacySettingsResponse: PrivacySettingsResponse {
        PrivacySettingsResponse(
            deliveryReceipts: deliveryReceipts.map { .init(enabled: $0.enabled) },
            readReceipts: readReceipts.map { .init(enabled: $0.enabled) },
            typingIndicators: typingIndicators.map { .init(enabled: $0.enabled) }
        )
    }
}

extension PrivacySettingsResponse {
    var asUserPrivacySettingsPayload: UserPrivacySettingsPayload {
        UserPrivacySettingsPayload(
            typingIndicators: typingIndicators.map { .init(enabled: $0.enabled) },
            readReceipts: readReceipts.map { .init(enabled: $0.enabled) },
            deliveryReceipts: deliveryReceipts.map { .init(enabled: $0.enabled) }
        )
    }
}

extension DraftResponse {
    var cid: ChannelId? {
        try? ChannelId(cid: channelCid)
    }
}

extension CreateDraftRequest {
    convenience init(
        id: String,
        text: String,
        command: String?,
        args: String?,
        parentId: String?,
        showReplyInChannel: Bool,
        isSilent: Bool,
        quotedMessageId: String?,
        attachments: [Attachment],
        mentionedUserIds: [UserId],
        extraData: [String: RawJSON]
    ) {
        let message = MessageRequest(
            attachments: attachments.isEmpty ? nil : attachments,
            custom: extraData.isEmpty ? nil : extraData,
            id: id,
            mentionedUsers: mentionedUserIds.isEmpty ? nil : mentionedUserIds,
            parentId: parentId,
            quotedMessageId: quotedMessageId,
            showInChannel: showReplyInChannel,
            silent: isSilent,
            text: text
        )
        if let command {
            message.custom = (message.custom ?? [:]).merging(["command": .string(command)]) { _, new in new }
        }
        if let args {
            message.custom = (message.custom ?? [:]).merging(["args": .string(args)]) { _, new in new }
        }
        self.init(message: message)
    }
}

extension UnreadCountsChannel {
    var channelIdValue: ChannelId {
        (try? ChannelId(cid: channelId)) ?? ChannelId(type: .messaging, id: channelId)
    }
}

extension UnreadCountsChannelType {
    var channelTypeValue: ChannelType {
        ChannelType(rawValue: channelType)
    }
}

extension UpdateMemberPartialRequest {
    enum MemberUpdateField: String, CaseIterable {
        case archived
        case pinned
    }

    var archived: Bool? {
        self.set?[MemberUpdateField.archived.rawValue]?.boolValue
    }

    var pinned: Bool? {
        self.set?[MemberUpdateField.pinned.rawValue]?.boolValue
    }

    var extraData: [String: RawJSON]? {
        guard var extraData = self.set else { return nil }
        MemberUpdateField.allCases.forEach { extraData[$0.rawValue] = nil }
        return extraData.isEmpty ? nil : extraData
    }

    convenience init(
        archived: Bool? = nil,
        pinned: Bool? = nil,
        extraData: [String: RawJSON]? = nil
    ) {
        var set = extraData ?? [:]
        if let archived {
            set[MemberUpdateField.archived.rawValue] = .bool(archived)
        }
        if let pinned {
            set[MemberUpdateField.pinned.rawValue] = .bool(pinned)
        }
        self.init(set: set.isEmpty ? nil : set)
    }
}

extension CreateGuestResponse {
    convenience init(user: OwnUserResponse, token: Token) {
        let userResponse = user.asUserResponse()
        userResponse.id = token.userId
        self.init(accessToken: token.rawValue, duration: "", user: userResponse)
    }

    func validatedToken() throws -> Token {
        let token = try Token(rawValue: accessToken)
        guard user.id == token.userId else {
            throw ClientError.InvalidToken("Token has different user_id")
        }
        return token
    }
}

extension UserResponse {
    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }

    var userRole: UserRole {
        UserRole(rawValue: role)
    }

    var teamsRolePayload: [String: UserRole]? {
        teamsRole?.mapValues { UserRole(rawValue: $0) }
    }

    convenience init(
        id: String,
        name: String?,
        imageURL: URL?,
        role: UserRole,
        teamsRole: [String: UserRole]?,
        createdAt: Date,
        updatedAt: Date,
        deactivatedAt: Date?,
        lastActiveAt: Date?,
        isOnline: Bool,
        isInvisible: Bool,
        isBanned: Bool,
        teams: [TeamId] = [],
        language: String?,
        avgResponseTime: Int? = nil,
        extraData: [String: RawJSON]
    ) {
        self.init(
            avgResponseTime: avgResponseTime,
            banned: isBanned,
            blockedUserIds: [],
            createdAt: createdAt,
            custom: extraData,
            deactivatedAt: deactivatedAt,
            id: id,
            image: imageURL?.absoluteString,
            language: language ?? "",
            lastActive: lastActiveAt,
            name: name,
            online: isOnline,
            role: role.rawValue,
            teams: teams,
            teamsRole: teamsRole?.mapValues(\.rawValue),
            updatedAt: updatedAt
        )
    }
}

extension FullUserResponse {
    func asUserResponse() -> UserResponse {
        UserResponse(
            id: id,
            name: name,
            imageURL: image.flatMap(URL.init(string:)),
            role: UserRole(rawValue: role),
            teamsRole: teamsRole?.mapValues { UserRole(rawValue: $0) },
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActive,
            isOnline: online,
            isInvisible: false,
            isBanned: banned,
            teams: teams,
            language: language,
            avgResponseTime: avgResponseTime,
            extraData: custom
        )
    }

    func asOwnUserResponse() -> OwnUserResponse {
        OwnUserResponse(
            id: id,
            name: name,
            imageURL: image.flatMap(URL.init(string:)),
            role: UserRole(rawValue: role),
            teamsRole: teamsRole?.mapValues { UserRole(rawValue: $0) },
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActive,
            isOnline: online,
            isInvisible: invisible,
            isBanned: banned,
            teams: teams,
            language: language.isEmpty ? nil : language,
            extraData: custom,
            devices: devices,
            mutedUsers: mutes,
            mutedChannels: channelMutes,
            unreadCount: .init(channels: unreadChannels, messages: unreadCount, threads: unreadThreads),
            privacySettings: privacySettings?.asUserPrivacySettingsPayload,
            blockedUserIds: Set(blockedUserIds),
            pushPreference: nil
        )
    }
}

extension QueryUsersResponse {
    var userPayloads: [UserResponse] {
        users.map { $0.asUserResponse() }
    }
}

extension UserRequest {
    var imageURL: URL? {
        image.flatMap(URL.init(string:))
    }
}

extension UpdateUserPartialRequest {
    var name: String? {
        self.set?["name"]?.stringValue
    }

    var imageURL: URL? {
        self.set?["image"]?.stringValue.flatMap(URL.init(string:))
    }

    var privacySettings: UserPrivacySettingsPayload? {
        guard let value = self.set?["privacy_settings"],
              let data = try? JSONEncoder.default.encode(value),
              let response = try? JSONDecoder.default.decode(PrivacySettingsResponse.self, from: data) else {
            return nil
        }
        return response.asUserPrivacySettingsPayload
    }

    var role: UserRole? {
        self.set?["role"]?.stringValue.map(UserRole.init(rawValue:))
    }

    var teamsRole: [TeamId: UserRole]? {
        guard let value = self.set?["teams_role"],
              let data = try? JSONEncoder.default.encode(value),
              let raw = try? JSONDecoder.default.decode([String: String].self, from: data) else {
            return nil
        }
        return raw.mapValues { UserRole(rawValue: $0) }
    }

    var extraData: [String: RawJSON]? {
        let reservedKeys = ["name", "image", "privacy_settings", "role", "teams_role"]
        let customData = (self.set ?? [:]).removingValues(forKeys: reservedKeys)
        return customData.isEmpty ? nil : customData
    }

    convenience init(
        name: String?,
        imageURL: URL?,
        privacySettings: UserPrivacySettingsPayload?,
        role: UserRole?,
        teamsRole: [TeamId: UserRole]?,
        extraData: [String: RawJSON]?
    ) {
        var set = extraData ?? [:]
        if let name {
            set["name"] = .string(name)
        }
        if let imageURL {
            set["image"] = .string(imageURL.absoluteString)
        }
        if let privacySettings {
            set["privacy_settings"] = privacySettings.asPrivacySettingsResponse.rawJSON
        }
        if let role {
            set["role"] = .string(role.rawValue)
        }
        if let teamsRole {
            set["teams_role"] = teamsRole.mapValues(\.rawValue).rawJSON
        }
        self.init(id: "", set: set.isEmpty ? nil : set, unset: nil)
    }
}

extension UpdateUsersResponse {
    func validatedUser() throws -> OwnUserResponse {
        guard let user = users.first?.value else {
            throw ClientError.Unexpected("Missing updated user.")
        }
        return user.asOwnUserResponse()
    }
}

private extension Encodable {
    var rawJSON: RawJSON? {
        guard let data = try? JSONEncoder.default.encode(self) else { return nil }
        return try? JSONDecoder.default.decode(RawJSON.self, from: data)
    }
}

extension UserResponse {
    func asFullUserResponse() -> FullUserResponse {
        FullUserResponse(
            avgResponseTime: avgResponseTime,
            banned: banned,
            blockedUserIds: [],
            channelMutes: [],
            createdAt: createdAt,
            custom: custom,
            deactivatedAt: deactivatedAt,
            devices: [],
            id: id,
            image: imageURL?.absoluteString,
            invisible: false,
            language: language,
            lastActive: lastActive,
            mutes: [],
            name: name,
            online: online,
            role: userRole.rawValue,
            shadowBanned: false,
            teams: teams,
            teamsRole: teamsRole,
            totalUnreadCount: 0,
            unreadChannels: 0,
            unreadCount: 0,
            unreadThreads: 0,
            updatedAt: updatedAt
        )
    }
}

extension ChannelResponse {
    // Compatibility shims for callers written against the legacy channel detail payload class.
    var name: String? { custom["name"]?.stringValue }
    var imageURL: URL? { custom["image"]?.stringValue.flatMap(URL.init(string:)) }

    var channelId: ChannelId? { try? ChannelId(cid: cid) }

    /// The channel's custom data with the reserved `name` and `image` keys removed,
    /// since those are surfaced as dedicated `name`/`imageURL` properties.
    var extraData: [String: RawJSON] {
        var extraData = custom
        extraData["name"] = nil
        extraData["image"] = nil
        return extraData
    }
}

extension ChannelStateResponseFields {
    // Compatibility shims for the legacy ChannelStateResponseFields struct.
    var newestMessage: MessageResponse? {
        guard let first = messages.first, let last = messages.last else { return nil }
        return first.createdAt > last.createdAt ? first : last
    }
}

extension ChannelStateResponse {
    var asChannelStateResponseFields: ChannelStateResponseFields {
        ChannelStateResponseFields(
            activeLiveLocations: activeLiveLocations,
            channel: channel,
            draft: draft,
            hidden: hidden,
            hideMessagesBefore: hideMessagesBefore,
            members: members,
            membership: membership,
            messages: messages,
            pendingMessages: pendingMessages,
            pinnedMessages: pinnedMessages,
            pushPreferences: pushPreferences,
            read: read,
            threads: threads,
            watcherCount: watcherCount,
            watchers: watchers
        )
    }
}

extension ChannelStateResponseFields {
    var asChannelStateResponse: ChannelStateResponse {
        ChannelStateResponse(
            activeLiveLocations: activeLiveLocations,
            channel: channel,
            draft: draft,
            duration: "",
            hidden: hidden,
            hideMessagesBefore: hideMessagesBefore,
            members: members,
            membership: membership,
            messages: messages,
            pendingMessages: pendingMessages,
            pinnedMessages: pinnedMessages,
            pushPreferences: pushPreferences,
            read: read,
            threads: threads,
            watcherCount: watcherCount,
            watchers: watchers
        )
    }
}

extension ChannelConfigWithInfo {
    var asChannelConfig: ChannelConfig {
        .init(
            reactionsEnabled: reactions,
            typingEventsEnabled: typingEvents,
            readEventsEnabled: readEvents,
            deliveryEventsEnabled: deliveryEvents,
            connectEventsEnabled: connectEvents,
            uploadsEnabled: uploads,
            repliesEnabled: replies,
            quotesEnabled: quotes,
            searchEnabled: search,
            mutesEnabled: mutes,
            pollsEnabled: polls,
            urlEnrichmentEnabled: urlEnrichment,
            skipLastMsgAtUpdateForSystemMsg: skipLastMsgUpdateForSystemMsgs,
            messageRemindersEnabled: userMessageReminders,
            sharedLocationsEnabled: sharedLocations,
            messageRetention: "",
            maxMessageLength: maxMessageLength,
            commands: commands.map(\.asCommand),
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

extension ChannelConfig {
    var asChannelConfigWithInfo: ChannelConfigWithInfo {
        .init(
            automod: .unknown,
            automodBehavior: .unknown,
            commands: commands.map(\.asCommandOpenAPI),
            connectEvents: connectEventsEnabled,
            countMessages: false,
            createdAt: createdAt,
            customEvents: false,
            deliveryEvents: deliveryEventsEnabled,
            markMessagesPending: false,
            maxMessageLength: maxMessageLength,
            mutes: mutesEnabled,
            name: "",
            polls: pollsEnabled,
            pushNotifications: false,
            quotes: quotesEnabled,
            reactions: reactionsEnabled,
            readEvents: readEventsEnabled,
            reminders: messageRemindersEnabled,
            replies: repliesEnabled,
            search: searchEnabled,
            sharedLocations: sharedLocationsEnabled,
            skipLastMsgUpdateForSystemMsgs: skipLastMsgAtUpdateForSystemMsg,
            typingEvents: typingEventsEnabled,
            updatedAt: updatedAt,
            uploads: uploadsEnabled,
            urlEnrichment: urlEnrichmentEnabled,
            userMessageReminders: messageRemindersEnabled
        )
    }
}

extension CommandPayload {
    var asCommand: Command {
        .init(name: name, description: description, set: set, args: args)
    }
}

extension Command {
    var asCommandOpenAPI: CommandPayload {
        .init(args: args, description: description, name: name, set: set)
    }
}

extension MessageResponse {
    /// Custom-data key under which the originating campaign id is stored.
    static let campaignIdCustomKey = "created_by_campaign_id"

    var campaignId: String? {
        if case let .string(value) = custom[Self.campaignIdCustomKey] {
            return value
        }
        return nil
    }
}

extension MessageWithChannelResponse {
    var asMessageResponse: MessageResponse {
        MessageResponse(
            attachments: attachments,
            cid: cid,
            command: command,
            createdAt: createdAt,
            custom: custom,
            deletedAt: deletedAt,
            deletedForMe: deletedForMe,
            deletedReplyCount: deletedReplyCount,
            draft: draft,
            html: html,
            i18n: i18n,
            id: id,
            imageLabels: imageLabels,
            latestReactions: latestReactions,
            member: member,
            mentionedChannel: mentionedChannel,
            mentionedGroupIds: mentionedGroupIds,
            mentionedHere: mentionedHere,
            mentionedRoles: mentionedRoles,
            mentionedUsers: mentionedUsers,
            messageTextUpdatedAt: messageTextUpdatedAt,
            mml: mml,
            moderation: moderation,
            ownReactions: ownReactions,
            parentId: parentId,
            pinExpires: pinExpires,
            pinned: pinned,
            pinnedAt: pinnedAt,
            pinnedBy: pinnedBy,
            poll: poll,
            pollId: pollId,
            quotedMessage: quotedMessage,
            quotedMessageId: quotedMessageId,
            reactionCounts: reactionCounts,
            reactionGroups: reactionGroups,
            reactionScores: reactionScores,
            reminder: reminder,
            replyCount: replyCount,
            restrictedVisibility: restrictedVisibility,
            shadowed: shadowed,
            sharedLocation: sharedLocation,
            showInChannel: showInChannel,
            silent: silent,
            text: text,
            threadParticipants: threadParticipants,
            type: type,
            updatedAt: updatedAt,
            user: user
        )
    }
}

extension SearchResultMessage {
    var asMessageResponse: MessageResponse {
        MessageResponse(
            attachments: attachments,
            cid: cid,
            command: command,
            createdAt: createdAt,
            custom: custom,
            deletedAt: deletedAt,
            deletedForMe: deletedForMe,
            deletedReplyCount: deletedReplyCount,
            draft: draft,
            html: html,
            i18n: i18n,
            id: id,
            imageLabels: imageLabels,
            latestReactions: latestReactions,
            member: member,
            mentionedChannel: mentionedChannel,
            mentionedGroupIds: mentionedGroupIds,
            mentionedHere: mentionedHere,
            mentionedRoles: mentionedRoles,
            mentionedUsers: mentionedUsers,
            messageTextUpdatedAt: messageTextUpdatedAt,
            mml: mml,
            moderation: moderation,
            ownReactions: ownReactions,
            parentId: parentId,
            pinExpires: pinExpires,
            pinned: pinned,
            pinnedAt: pinnedAt,
            pinnedBy: pinnedBy,
            poll: poll,
            pollId: pollId,
            quotedMessage: quotedMessage,
            quotedMessageId: quotedMessageId,
            reactionCounts: reactionCounts,
            reactionGroups: reactionGroups,
            reactionScores: reactionScores,
            reminder: reminder,
            replyCount: replyCount,
            restrictedVisibility: restrictedVisibility,
            shadowed: shadowed,
            sharedLocation: sharedLocation,
            showInChannel: showInChannel,
            silent: silent,
            text: text,
            threadParticipants: threadParticipants,
            type: type,
            updatedAt: updatedAt,
            user: user
        )
    }
}

extension ReminderResponseData {
    var channelId: ChannelId? {
        try? ChannelId(cid: channelCid)
    }
}

extension PollVoteResponseData {
    var optionalOptionId: String? {
        optionId.isEmpty ? nil : optionId
    }
}

extension PushPreferencesResponse {
    func asModel() -> PushPreference {
        .init(
            level: PushPreferenceLevel(rawValue: chatLevel ?? PushPreferenceLevel.all.rawValue),
            disabledUntil: disabledUntil
        )
    }
}

extension ChannelPushPreferencesResponse {
    func asModel() -> PushPreference {
        .init(
            level: PushPreferenceLevel(rawValue: chatLevel ?? PushPreferenceLevel.all.rawValue),
            disabledUntil: disabledUntil
        )
    }
}

extension UpsertPushPreferencesResponse {
    var channelPreferences: [String: [String: ChannelPushPreferencesResponse]] {
        userChannelPreferences.mapValues { $0.compactMapValues { $0 } }
    }
}

extension [String: PushPreferencesResponse?] {
    func asModel() -> [PushPreference] {
        values.compactMap { $0?.asModel() }
    }
}

extension [String: PushPreferencesResponse] {
    func asModel() -> [PushPreference] {
        values.map { $0.asModel() }
    }
}

extension [String: [String: ChannelPushPreferencesResponse]] {
    func asModel() -> [ChannelId: PushPreference] {
        .init(uniqueKeysWithValues: values
            .flatMap { $0 }
            .compactMap { key, value in
                guard let channelId = try? ChannelId(cid: key) else { return nil }
                return (channelId, value.asModel())
            })
    }
}

extension PaginationParams {
    convenience init(_ pagination: Pagination) {
        // Mirrors `Pagination.encode`: omit limit at the backend default, omit offset when 0 or a cursor is present.
        self.init(
            limit: pagination.pageSize == .backendDefaultPageSize ? nil : pagination.pageSize,
            offset: pagination.cursor == nil && pagination.offset != 0 ? pagination.offset : nil
        )
    }
}

extension MessagePaginationParams {
    convenience init(_ pagination: MessagesPagination) {
        self.init(limit: pagination.pageSize)
        switch pagination.parameter {
        case let .greaterThan(id): idGt = id
        case let .greaterThanOrEqual(id): idGte = id
        case let .lessThan(id): idLt = id
        case let .lessThanOrEqual(id): idLte = id
        case let .around(id): idAround = id
        case .none: break
        }
    }
}

extension ChannelGetOrCreateRequest {
    convenience init(query: ChannelQuery) {
        self.init(
            data: query.channelPayload,
            members: query.membersPagination.map { PaginationParams($0) },
            messages: query.pagination.map { MessagePaginationParams($0) },
            presence: query.options.contains(.presence) ? true : nil,
            state: query.options.contains(.state) ? true : nil,
            watch: query.options.contains(.watch) ? true : nil,
            watchers: query.watchersLimit.map { PaginationParams(Pagination(pageSize: $0)) }
        )
    }
}

extension QueryMembersPayload {
    convenience init(query: ChannelMemberListQuery) {
        let sort = query.sort.map {
            SortParamRequest(direction: $0.isAscending ? 1 : -1, field: $0.key.remoteKey)
        }
        self.init(
            filterConditions: query.filter?.toRawJSONDictionary() ?? [:],
            id: query.cid.id,
            limit: query.pagination.pageSize,
            offset: query.pagination.offset == 0 ? nil : query.pagination.offset,
            sort: sort.isEmpty ? nil : sort,
            type: query.cid.type.rawValue
        )
    }
}

extension UpdateChannelPartialRequest {
    convenience init(channelInput: ChannelInput, unsetProperties: [String]) throws {
        self.init(set: try channelInput.asRawJSONDictionary(), unset: unsetProperties)
    }
}

extension ConfigOverridesRequest {
    convenience init(_ channelConfig: ChannelConfigPayload) {
        self.init(
            blocklist: channelConfig.blocklist,
            blocklistBehavior: channelConfig.blocklistBehavior.map { .init(rawValue: $0.rawValue) ?? .unknown },
            chatPreferences: channelConfig.chatPreferences,
            commands: channelConfig.commands,
            countMessages: channelConfig.countMessages,
            grants: channelConfig.grants,
            maxMessageLength: channelConfig.maxMessageLength,
            pushLevel: channelConfig.pushLevel.map { .init(rawValue: $0.rawValue) ?? .unknown },
            quotes: channelConfig.quotes,
            reactions: channelConfig.reactions,
            replies: channelConfig.replies,
            sharedLocations: channelConfig.sharedLocations,
            typingEvents: channelConfig.typingEvents,
            uploads: channelConfig.uploads,
            urlEnrichment: channelConfig.urlEnrichment,
            userMessageReminders: channelConfig.userMessageReminders
        )
    }
}

extension ChannelInputRequest {
    convenience init(channelInput: ChannelInput) {
        self.init(
            autoTranslationEnabled: channelInput.autoTranslationEnabled,
            autoTranslationLanguage: channelInput.autoTranslationLanguage,
            configOverrides: channelInput.configOverrides.map { ConfigOverridesRequest($0) },
            createdBy: channelInput.createdBy,
            custom: channelInput.custom,
            disabled: channelInput.disabled,
            frozen: channelInput.frozen,
            invites: channelInput.invites,
            members: channelInput.members,
            team: channelInput.team
        )
    }
}

extension ChannelMemberRequest {
    convenience init(memberInfo: MemberInfoRequest) {
        self.init(custom: memberInfo.extraData, userId: memberInfo.userId)
    }
}

extension UpdateMessagePartialRequest {
    convenience init(_ request: MessagePartialUpdateRequest) throws {
        self.init(
            set: try request.set?.asRawJSONDictionary(),
            skipEnrichUrl: request.skipEnrichUrl,
            unset: request.unset
        )
    }
}

extension SearchPayload {
    convenience init(query: MessageSearchQuery) {
        let sort = query.sort.map {
            SortParamRequest(direction: $0.isAscending ? 1 : -1, field: $0.key.remoteKey)
        }
        self.init(
            filterConditions: query.channelFilter.toRawJSONDictionary(),
            limit: query.pagination?.pageSize,
            messageFilterConditions: query.messageFilter.toRawJSONDictionary(),
            next: query.pagination?.cursor,
            offset: query.pagination.flatMap { $0.cursor == nil && $0.offset != 0 ? $0.offset : nil },
            sort: sort.isEmpty ? nil : sort
        )
    }
}

extension SendEventRequest {
    convenience init<Payload: CustomEventPayload>(payload: Payload) {
        let data = try? JSONEncoder.default.encode(payload)
        var custom = data.flatMap { try? JSONDecoder.default.decode([String: RawJSON].self, from: $0) } ?? [:]
        // Strip the `type` field that CustomEventPayload encoders include — the
        // server takes the type from the outer EventRequest.type, not the payload.
        custom["type"] = nil
        self.init(event: EventRequest(
            custom: custom.isEmpty ? nil : custom,
            type: type(of: payload).eventType.rawValue
        ))
    }
}

extension FlagRequest {
    convenience init(
        reason: String? = nil,
        targetMessageId: String? = nil,
        targetUserId: String? = nil,
        custom: [String: RawJSON]? = nil
    ) {
        self.init(
            custom: custom,
            entityId: targetMessageId ?? targetUserId ?? "",
            entityType: targetMessageId == nil ? "user" : "message",
            reason: reason
        )
    }
}

extension UserResponse {
    func asOwnUserResponse() -> OwnUserResponse {
        OwnUserResponse(
            id: id,
            name: name,
            imageURL: imageURL,
            role: userRole,
            teamsRole: teamsRolePayload,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deactivatedAt: deactivatedAt,
            lastActiveAt: lastActive,
            isOnline: online,
            isInvisible: false,
            isBanned: banned,
            teams: teams,
            language: language.isEmpty ? nil : language,
            extraData: custom,
            pushPreference: nil
        )
    }
}

extension Attachment {
    convenience init(type: AttachmentType, payload: RawJSON) {
        let attachment: Attachment? = {
            guard let data = try? JSONEncoder.default.encode(payload) else { return nil }
            return try? JSONDecoder.default.decode(Attachment.self, from: data)
        }()
        if let attachment {
            self.init(
                actions: attachment.actions,
                assetUrl: attachment.assetUrl,
                authorIcon: attachment.authorIcon,
                authorLink: attachment.authorLink,
                authorName: attachment.authorName,
                color: attachment.color,
                custom: attachment.custom,
                fallback: attachment.fallback,
                fields: attachment.fields,
                footer: attachment.footer,
                footerIcon: attachment.footerIcon,
                giphy: attachment.giphy,
                imageUrl: attachment.imageUrl,
                ogScrapeUrl: attachment.ogScrapeUrl,
                originalHeight: attachment.originalHeight,
                originalWidth: attachment.originalWidth,
                pretext: attachment.pretext,
                text: attachment.text,
                thumbUrl: attachment.thumbUrl,
                title: attachment.title,
                titleLink: attachment.titleLink
            )
        } else {
            var dict = payload.dictionaryValue ?? [:]
            dict.removeValue(forKey: AttachmentCodingKeys.type.rawValue)
            self.init(custom: dict)
        }
        self.type = type.rawValue
    }

    var attachmentType: AttachmentType {
        if ogScrapeUrl != nil {
            return .linkPreview
        }
        return type.map(AttachmentType.init(rawValue:)) ?? .unknown
    }

    var payload: RawJSON {
        guard
            let data = try? JSONEncoder.default.encode(self),
            case var .dictionary(dict) = (try? JSONDecoder.default.decode(RawJSON.self, from: data)) ?? .dictionary([:])
        else {
            return .dictionary([:])
        }
        dict.removeValue(forKey: AttachmentCodingKeys.type.rawValue)
        if case let .dictionary(customDict) = dict["custom"] ?? .dictionary([:]) {
            for (key, value) in customDict {
                dict[key] = value
            }
        }
        dict.removeValue(forKey: "custom")
        return .dictionary(dict)
    }
}

// MARK: - Endpoint compatibility wrappers

//
// Factories below keep existing call sites small while delegating to generated
// OpenAPI endpoints wherever the operation and model shape match.

extension Endpoint {
    /// Loads the pinned messages of a channel. The OpenAPI spec does not expose
    /// a `pinned_messages` operation, so the path is built manually.
    static func pinnedMessages(cid: ChannelId, query: PinnedMessagesQuery) -> Endpoint<MessageListPayload> {
        .init(
            path: .custom("channels/\(cid.apiPath)/pinned_messages"),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["payload": query]
        )
    }

    /// Unbans a channel member. The OpenAPI `ban` operation is POST-only;
    /// `DELETE /moderation/ban` has no generated factory yet.
    static func unbanMember(_ userId: UserId, cid: ChannelId) -> Endpoint<EmptyResponse> {
        .init(
            path: .custom("moderation/ban"),
            method: .delete,
            queryItems: [
                "target_user_id": userId,
                "channel_cid": cid.rawValue
            ],
            requiresConnectionId: false,
            body: nil
        )
    }

    /// WebSocket connect endpoint. The OpenAPI spec exposes `longPoll` for the
    /// long-polling fallback, but the actual WebSocket establishment uses
    /// `?json=<payload>` on `/connect` with a hand-shaped auth body.
    static func webSocketConnect(userInfo: UserInfo) -> Endpoint<EmptyResponse> {
        .init(
            path: .custom("connect"),
            method: .get,
            queryItems: nil,
            requiresConnectionId: false,
            body: [
                "json": WSAuthMessage(
                    products: nil,
                    token: "",
                    userDetails: ConnectUserDetailsRequest(
                        custom: userInfo.extraData,
                        id: userInfo.id,
                        image: userInfo.imageURL?.absoluteString,
                        invisible: userInfo.isInvisible,
                        language: userInfo.language?.languageCode,
                        name: userInfo.name,
                        privacySettings: userInfo.privacySettings.map {
                            UserPrivacySettingsPayload(settings: $0).asPrivacySettingsResponse
                        }
                    )
                )
            ]
        )
    }

    /// Channel query endpoint used by `ChannelRepository.getChannel` and the
    /// channel-already-exists hot path.
    static func channelQuery(_ query: ChannelQuery, requiresConnectionId: Bool? = nil) -> Endpoint<ChannelStateResponse> {
        let request = ChannelGetOrCreateRequest(query: query)
        return .init(
            path: query.id.map { .getOrCreateChannel(type: query.type.rawValue, id: $0) } ?? .getOrCreateDistinctChannel(type: query.type.rawValue),
            method: .post,
            queryItems: nil,
            requiresConnectionId: requiresConnectionId ?? query.options.contains(oneOf: [.presence, .state, .watch]),
            body: request
        )
    }

    /// Channel watcher list — uses channel query endpoint with a watcher-shaped query.
    static func channelWatchers(query: ChannelWatcherListQuery) -> Endpoint<ChannelStateResponse> {
        .init(
            path: .getOrCreateChannel(type: query.cid.type.rawValue, id: query.cid.id),
            method: .post,
            queryItems: nil,
            requiresConnectionId: true,
            body: query
        )
    }

    /// User unmute — OpenAPI only exposes channel unmute, so this endpoint
    /// remains custom until the user unmute operation is generated.
    static func unmuteUser(_ userId: UserId) -> Endpoint<EmptyResponse> {
        .init(
            path: .custom("moderation/unmute"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: ["target_id": userId]
        )
    }

    /// Flag / unflag a user. Flag delegates to the generated endpoint; unflag
    /// stays custom until OpenAPI exposes a generated unflag operation.
    static func flagUser(_ flag: Bool, with userId: UserId, reason: String? = nil, extraData: [String: RawJSON]? = nil) -> Endpoint<FlagResponse> {
        if flag {
            return .flag(flagRequest: FlagRequest(reason: reason, targetUserId: userId, custom: extraData))
        }
        return .init(
            path: .custom("moderation/\(flag ? "flag" : "unflag")"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: FlagRequest(reason: reason, targetMessageId: nil, targetUserId: userId, custom: extraData)
        )
    }

    /// Flag / unflag a message. Flag delegates to the generated endpoint; unflag
    /// stays custom until OpenAPI exposes a generated unflag operation.
    static func flagMessage(_ flag: Bool, with messageId: MessageId, reason: String? = nil, extraData: [String: RawJSON]? = nil) -> Endpoint<FlagResponse> {
        if flag {
            return .flag(flagRequest: FlagRequest(reason: reason, targetMessageId: messageId, custom: extraData))
        }
        return .init(
            path: .custom("moderation/\(flag ? "flag" : "unflag")"),
            method: .post,
            queryItems: nil,
            requiresConnectionId: false,
            body: FlagRequest(reason: reason, targetMessageId: messageId, targetUserId: nil, custom: extraData)
        )
    }
}
